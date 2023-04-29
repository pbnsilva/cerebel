package suggester

type Item struct {
	Suggestion *input   `json:"suggestion"`
	Gender     []string `json:"gender"`
}

type contexts struct {
	Gender []string `json:"gender,omitempty"`
}

type input struct {
	Input    []string  `json:"input"`
	Weight   int       `json:"weight,omitempty"`
	Contexts *contexts `json:"contexts,omitempty"`
}

func NewItem(values []string, gender []string) *Item {
	return &Item{Suggestion: &input{Input: values, Contexts: &contexts{gender}}}
}

func NewItemWithWeight(values []string, weight int, gender []string) *Item {
	return &Item{Suggestion: &input{values, weight, &contexts{gender}}}
}

type Suggestion struct {
	Value  string `json:"value"`
	Offset *int   `json:"offset,omitempty"`
}
