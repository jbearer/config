import gdb

def ls(argv):
    if argv:
            # We don't yet support parsing args, just pass it off to gdb list
            gdb.execute('list {}'.format(argv))
            return

    cur_line = gdb.execute('bt 1', to_string=True).split('\n')[0]
    assert cur_line[:2] == '#0'
    line_num = int(cur_line.split(':')[-1])

    source = gdb.execute('list', to_string=True).split('\n')
    for i, line in enumerate(source):
        words = line.split('\t')
        if int(words[0]) == line_num:
            words[0] = pad('=>', len(words[0]))
            source[i] = '\t'.join(words)
            break

    print('\n'.join(source))

def pad(msg, length):
    return ' '*(length - len(msg)) + msg

class List(gdb.Command):
    def __init__(self):
        gdb.Command.__init__(self, 'ls', gdb.COMMAND_FILES, gdb.COMPLETE_NONE)

    def invoke(self, arg, _):
        ls(gdb.string_to_argv(arg))

List()
