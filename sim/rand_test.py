import os, random, subprocess

N_INSTR   = 40      
MAX_SEEDS = 200
MIN_SEEDS = 20      

RTL = ['top_file.v', 'cpu_file.v', 'pc_reg.v', 'rom_file.v', 'control_unit_file.v',
       'reg_file.v', 'imm_gen_file.v', 'alu.v', 'ram_file.v']


R_OPS   = {'add': (0x00, 0), 'sub': (0x20, 0), 'sll': (0x00, 1), 'slt': (0x00, 2),
           'xor': (0x00, 4), 'srl': (0x00, 5), 'or':  (0x00, 6), 'and': (0x00, 7)}
I_OPS   = {'addi': 0, 'slti': 2, 'xori': 4, 'ori': 6, 'andi': 7}
SH_OPS  = {'slli': 1, 'srli': 5}

ALL_OPS = list(R_OPS) + list(I_OPS) + list(SH_OPS) + ['lui']
REGS    = list(range(1, 8))       

ALL_BINS = {f'op_{o}' for o in ALL_OPS} | {
    'rd_x0', 'src_x0', 'slt_true', 'slt_false', 'shift_0', 'shift_31',
    'add_carry', 'sub_neg', 'imm_neg', 'imm_max', 'imm_min'}

M = 0xFFFFFFFF
#construction des instructions
def r_type(f7, rs2, rs1, f3, rd): return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x33
def i_type(imm, rs1, f3, rd):     return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x13
def u_type(imm20, rd):            return (imm20 << 12) | (rd << 7) | 0x37
def s_type(imm, rs2, rs1, f3):    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1F) << 7) | 0x23

#conversion en entier signé
def s32(x): return x - (1 << 32) if x >> 31 else x

#calcul des reférences
def alu(op, a, b):
    base = op[:-1] if op.endswith('i') else op      # addi -> add, slli -> sll...
    if base == 'add': return (a + b) & M
    if base == 'sub': return (a - b) & M
    if base == 'and': return a & b
    if base == 'or':  return a | b
    if base == 'xor': return a ^ b
    if base == 'slt': return int(s32(a) < s32(b))
    if base == 'sll': return (a << (b & 31)) & M
    if base == 'srl': return a >> (b & 31)

def gen(seed):  #genere une seed (= un ensemble d'instructions)
    rnd = random.Random(seed)
    regs, words, asm, cov = [0] * 32, [], [], set()

    def emit(word, text):
        words.append(word); asm.append(text)

    # Valeurs initiales aléatoires dans x1..x7
    for r in REGS:
        hi, lo = rnd.randrange(1 << 20), rnd.randrange(-2048, 2048)
        emit(u_type(hi, r), f'lui  x{r}, {hi:#x}')
        emit(i_type(lo, r, 0, r), f'addi x{r}, x{r}, {lo}')
        regs[r] = ((hi << 12) + lo) & M

    for _ in range(N_INSTR): #generation instructions random
        op  = rnd.choice(ALL_OPS)
        rd  = 0 if rnd.random() < 0.05 else rnd.choice(REGS)        # x0 de temps en temps
        rs1 = rnd.choice([0] + REGS)
        rs2 = rnd.choice([0] + REGS)
        a, b = regs[rs1], regs[rs2]
        cov.add(f'op_{op}')
        if rd == 0: cov.add('rd_x0')

        if op in R_OPS:
            f7, f3 = R_OPS[op]
            emit(r_type(f7, rs2, rs1, f3, rd), f'{op:4s} x{rd}, x{rs1}, x{rs2}')
            srcs = [rs1, rs2]
        elif op in I_OPS:
            imm = rnd.choice([0, 1, -1, 2047, -2048, rnd.randrange(-2048, 2048)])
            emit(i_type(imm, rs1, I_OPS[op], rd), f'{op:4s} x{rd}, x{rs1}, {imm}')
            b, srcs = imm & M, [rs1]
            if imm < 0:       cov.add('imm_neg')
            if imm == 2047:   cov.add('imm_max')
            if imm == -2048:  cov.add('imm_min')
        elif op in SH_OPS:
            b = rnd.choice([0, 31, rnd.randrange(32)])
            emit(i_type(b, rs1, SH_OPS[op], rd), f'{op:4s} x{rd}, x{rs1}, {b}')
            srcs = [rs1]
        else:                                                         # lui
            imm20 = rnd.randrange(1 << 20)
            emit(u_type(imm20, rd), f'lui  x{rd}, {imm20:#x}')
            regs_val = (imm20 << 12) & M
            if rd: regs[rd] = regs_val
            continue

        val = alu(op, a, b)

        if 0 in srcs: cov.add('src_x0')
        if op in ('sll', 'srl', 'slli', 'srli'):
            if b & 31 == 0:  cov.add('shift_0')
            if b & 31 == 31: cov.add('shift_31')
        if op in ('slt', 'slti'): cov.add('slt_true' if val else 'slt_false')
        if op in ('add', 'addi') and a + b > M: cov.add('add_carry')
        if op == 'sub' and val >> 31:           cov.add('sub_neg')

        if rd: regs[rd] = val                                         # x0 reste à 0

    emit(u_type(0x40000, 8), 'lui  x8, 0x40000')
    for r in REGS:
        emit(s_type(0, r, 8, 2), f'sw   x{r}, 0(x8)')
    emit(0x0000006F, 'j .')

    return words, asm, [regs[r] for r in REGS], cov

def run_rtl(words):
    os.makedirs('rand_run', exist_ok=True)
    with open('rand_run/firmware.hex', 'w') as f:
        f.write('\n'.join(f'{w:08x}' for w in words) + '\n')
    open('rand_run/dataram.hex', 'w').close()
    out = subprocess.run(['vvp', '../rand_sim'], cwd='rand_run',
                         capture_output=True, text=True).stdout
    return [int(l.split()[1], 16) for l in out.splitlines() if l.startswith('OUT')]

def main():
    subprocess.run(['iverilog', '-o', 'rand_sim', 'rand_tb.v'] + RTL, check=True)
    hit, fails, closed_at = set(), 0, None

    for seed in range(1, MAX_SEEDS + 1):
        words, asm, expected, cov = gen(seed)
        got = run_rtl(words)
        hit |= cov
        ok = (got == expected)
        if not ok:
            fails += 1
            with open(f'fail_seed{seed}.txt', 'w') as f:
                f.write('\n'.join(asm) + '\n\n')
                f.write(f'attendu : {[hex(x) for x in expected]}\n')
                f.write(f'obtenu  : {[hex(x) for x in got]}\n')
        print(f'seed {seed:3d}  {"PASS" if ok else "FAIL"}  coverage {len(hit)}/{len(ALL_BINS)}')

        if closed_at is None and hit == ALL_BINS:
            closed_at = seed
        if closed_at and seed >= MIN_SEEDS:
            break

    print(f'\nCoverage : {len(hit)}/{len(ALL_BINS)}'
          + (f' (caught : seed {closed_at})' if closed_at else ''))
    if hit != ALL_BINS:
        print('Cas non couverts :', sorted(ALL_BINS - hit))
    print(f'Échecs : {fails}')
    raise SystemExit(1 if fails else 0)

if __name__ == '__main__':
    main()