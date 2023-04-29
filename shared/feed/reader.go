package feed

type Reader interface {
	Read() bool
	Item() (Item, error)
}
