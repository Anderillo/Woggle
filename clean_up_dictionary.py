import re

# This dictionary.txt file was retrieved from https://raw.githubusercontent.com/scrabblewords/scrabblewords/main/words/North-American/NWL2020.txt
with open('assets/dictionary.txt') as file:
    lines = [line.rstrip() for line in file]
    for i in range(len(lines)):
        definitions = lines[i].split(' / ')
        for j in range(len(definitions)):
            if len(definitions[j].split('[')) > 1:
                word_type = definitions[j].split('[')[1].split(' ')[0].replace(']', '')
                if word_type == 'n': word_type = 'noun'
                elif word_type == 'v': word_type = 'verb'
                elif word_type == 'adj': word_type = 'adjective'
                elif word_type == 'adv': word_type = 'adverb'
                elif word_type == 'interj': word_type = 'interjection'
                elif word_type == 'prep': word_type = 'preposition'
                definitions[j] = definitions[j].split('[')[0] + '(' + word_type + ')'
            definitions[j] = re.sub(r'\{(\w+)=[^\}]*\}', r'[\1]', definitions[j])
            definitions[j] = re.sub(r'<(\w+)=[^\>]*>', r'form of [\1]', definitions[j])
        lines[i] = ' / '.join(definitions) + '\n'
    f = open('assets/dictionary_clean.txt', 'w')
    f.writelines(lines)
    f.close()