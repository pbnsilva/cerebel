package config

import (
	"errors"
	"os"
	"reflect"
	"strconv"
	"strings"
)

var ErrNotAStruct = errors.New("GetEnvInfo: input data should be a struct!")

func BindFromEnv(cfg Configer) error {
	if err := bindInterfaceFromEnv(cfg.GetBase()); err != nil {
		return err
	}
	return bindInterfaceFromEnv(cfg)
}

func bindInterfaceFromEnv(data interface{}) error {
	e := reflect.ValueOf(data).Elem()
	if e.Kind() != reflect.Struct {
		return ErrNotAStruct
	}

	typeOfData := e.Type()
	for i := 0; i < e.NumField(); i++ {
		field := e.Field(i)

		if !field.CanSet() {
			continue
		}

		fieldName := typeOfData.Field(i).Tag.Get("env")
		if fieldName == "" {
			// no tag `env` provided, skip the field
			continue
		}

		key := fieldName
		key = strings.ToUpper(fieldName)

		value := os.Getenv(key)
		if value == "" {
			continue
		}

		switch field.Kind() {
		case reflect.String:
			field.SetString(value)

		case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
			intValue, err := strconv.ParseInt(value, 0, field.Type().Bits())
			if err != nil {
				return err
			}
			field.SetInt(intValue)

		case reflect.Bool:
			boolValue, err := strconv.ParseBool(value)
			if err != nil {
				return err
			}
			field.SetBool(boolValue)

		case reflect.Float32, reflect.Float64:
			floatValue, err := strconv.ParseFloat(value, field.Type().Bits())
			if err != nil {
				return err
			}
			field.SetFloat(floatValue)
		}
	}

	return nil
}
