package applicant

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
)

type ArthurClient struct {
	entityID   string
	httpClient *http.Client
	url        string
}

func NewArthurClient(entityID string, httpClient *http.Client, url string) *ArthurClient {
	return &ArthurClient{entityID, httpClient, url}
}

func (c *ArthurClient) GetApplicantID(ctx context.Context, token, email string) (string, error) {
	// TODO: need to add specific endpoint path to url
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.url, nil)
	if err != nil {
		return "", fmt.Errorf("building request: %w", err)
	}

	queryParam := req.URL.Query()
	queryParam.Add("email", email)

	req.URL.RawQuery = queryParam.Encode()

	req.Header.Set("X-EntityID", c.entityID)
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("making request: %w", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return "", fmt.Errorf("arthur responded with status code: %d", resp.StatusCode)
	}

	listApplicantsResponse := &ListApplicantsResponse{}
	if err := json.NewDecoder(resp.Body).Decode(listApplicantsResponse); err != nil {
		return "", fmt.Errorf("decoding response: %w", err)
	}

	if len(listApplicantsResponse.Data) < 1 {
		return "", fmt.Errorf("returned no applicants in response")
	}

	return listApplicantsResponse.Data[0].ID, nil
}

func (c *ArthurClient) UpdateApplicantStatus(ctx context.Context, token, applicantID, updatedStatus string) error {
	reqStruct := &ApplicantStatusUpdateRequest{Status: updatedStatus}

	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(reqStruct); err != nil {
		return fmt.Errorf("encoding request: %w", err)
	}

	// TODO: need to add specific endpoint path to url
	req, err := http.NewRequestWithContext(ctx, http.MethodPut, c.url, &buf)
	if err != nil {
		return fmt.Errorf("building request: %w", err)
	}

	req.Header.Set("X-EntityID", c.entityID)
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("making request: %w", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		return fmt.Errorf("arthur responded with status code: %d", resp.StatusCode)
	}

	return nil
}
