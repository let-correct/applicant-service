package applicant

type ListApplicantsResponse struct {
	Status int         `json:"status"`
	Data   []Applicant `json:"data"`
}

type Applicant struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}
