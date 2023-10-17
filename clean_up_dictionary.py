import re

with open('assets/dictionary.txt') as file:
    lines = [line.rstrip() for line in file]
    for i in range(len(lines)):
        if len(lines[i].split('[')) > 1:
            word_type = lines[i].split('[')[1].split(' ')[0].replace(']', '')
            if word_type == 'n': word_type = 'noun'
            elif word_type == 'v': word_type = 'verb'
            elif word_type == 'adj': word_type = 'adjective'
            elif word_type == 'adv': word_type = 'adverb'
            elif word_type == 'interj': word_type = 'interjection'
            elif word_type == 'prep': word_type = 'preposition'
            lines[i] = lines[i].split('[')[0] + '(' + word_type + ')'
        lines[i] = re.sub(r'\{(\w+)=[^\}]*\}', r'[\1]', lines[i])
        lines[i] = re.sub(r'<(\w+)=[^\>]*>', r'form of [\1]', lines[i])
        lines[i] = lines[i] + '\n'
    f = open('assets/dictionary_clean.txt', 'w')
    f.writelines(lines)
    f.close()