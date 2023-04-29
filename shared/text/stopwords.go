package text

import (
	"bytes"
	"regexp"

	"github.com/petard/cerebel/shared/text/stopwords"

	"golang.org/x/text/language"
	"golang.org/x/text/unicode/norm"
)

var (
	remTags      = regexp.MustCompile(`<[^>]*>`)
	oneSpace     = regexp.MustCompile(`\s{2,}`)
	unicodeWords = regexp.MustCompile(`[\pL\p{Mc}\p{Mn}-_']+`)
)

func RemoveStopWords(content []byte, langCode string) []byte {
	//Parse language
	tag := language.Make(langCode)
	base, _ := tag.Base()
	langCode = base.String()

	//Remove stop words by using a list of most frequent words
	switch langCode {
	case "en":
		content = removeStopWords(content, stopwords.English)
	}

	//Remove duplicated space characters
	content = oneSpace.ReplaceAll(content, []byte(" "))

	return content
}

func removeStopWords(content []byte, dict map[string]string) []byte {
	var result []byte
	content = norm.NFC.Bytes(content)
	content = bytes.ToLower(content)
	words := unicodeWords.FindAll(content, -1)
	for _, w := range words {
		//log.Println(w)
		if _, ok := dict[string(w)]; ok {
			result = append(result, ' ')
		} else {
			result = append(result, []byte(w)...)
			result = append(result, ' ')
		}
	}
	return result
}
