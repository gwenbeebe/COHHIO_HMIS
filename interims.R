
load("images/COHHIOHMIS.RData")

library(tidyverse)
library(lubridate)
library(readxl)
library(HMIS)
library(janitor)

ReportStart <- "10012019"
ReportEnd <- "09302020"

Interims <-
  read_xlsx(paste0(directory, "/RMisc2.xlsx"), sheet = 20) %>%
  mutate(InterimDate = as.Date(InterimDate, origin = "1899-12-30"))

small_enrollment <- Enrollment %>%
  select(PersonalID,
         EnrollmentID,
         HouseholdID,
         ProjectName,
         EntryDate,
         MoveInDate,
         MoveInDateAdjust,
         HHMoveIn,
         ExitDate,
         ExitAdjust) %>%
  filter(served_between(., ReportStart, ReportEnd))

enrollments_interims <- small_enrollment %>%
  left_join(Interims, by = c("EnrollmentID", "PersonalID"))

hmid_matches_entry <- enrollments_interims %>%
  filter(ymd(MoveInDateAdjust) == ymd(EntryDate)) %>%
  select(PersonalID, EnrollmentID, HouseholdID) %>%
  unique()

interim_dates_that_match_hmid <- enrollments_interims %>%
  filter(ymd(InterimDate) == ymd(MoveInDateAdjust)) %>%
  select(PersonalID, EnrollmentID, HouseholdID) %>%
  unique()

# if hud answers that ws is correct about the Exit Date, then you'll 
# have to modify this to exclude ees where the hmid == the exit date
no_valid_hmid <- enrollments_interims %>%
  filter(is.na(MoveInDateAdjust)) %>%
  select(PersonalID, EnrollmentID, HouseholdID) %>%
  unique()

hmid_not_in_date_range <- enrollments_interims %>%
  filter(ymd(MoveInDateAdjust) >= mdy(ReportStart) & 
           ymd(MoveInDateAdjust) < mdy(ReportEnd)) %>%
  select(PersonalID, EnrollmentID, HouseholdID) %>%
  unique()
  
missing_interims <- enrollments_interims %>%
  anti_join(hmid_matches_entry, by = c("PersonalID", "EnrollmentID", "HouseholdID")) %>%
  anti_join(interim_dates_that_match_hmid, by = c("PersonalID", "EnrollmentID", "HouseholdID")) %>%
  anti_join(no_valid_hmid, by = c("PersonalID", "EnrollmentID", "HouseholdID")) %>%
  anti_join(hmid_not_in_date_range, by = c("PersonalID", "EnrollmentID", "HouseholdID")) %>%
  mutate(
    Issue = case_when(
      is.na(InterimID) ~ "No Interim at all",
      ymd(InterimDate) != ymd(MoveInDateAdjust) &
        ymd(EntryDate) != ymd(MoveInDateAdjust) ~ "Move In Date doesn't match Interim Date",
      ymd(MoveInDateAdjust) == ymd(ExitDate) ~ "Move In Date matches Exit Date"
    )
  ) %>%
  select(PersonalID, EnrollmentID, HouseholdID, ProjectName, EntryDate, Issue) %>%
  unique()

whos_the_worst <- missing_interims %>%
  group_by(ProjectName, Issue) %>%
  summarise(Total = n()) %>%
  arrange(desc(Total))

# Experiment with the APR -------------------------------------------------

# LSA2 APR for a given provider

provider_name <- "Licking - LCCH - RROhio - RRH"

APR_moved_in <- read_csv("random_data/movedin.csv")

APR_served <- read_csv("random_data/served.csv")

clients_that_did_not_move_in <- setdiff(APR_served, APR_moved_in) %>%
  rename("PersonalID" = 1)

full_data_of_no_move_ins <- enrollments_interims %>%
  filter(ProjectName == provider_name) %>%
  right_join(clients_that_did_not_move_in) %>%
  mutate(
    why = case_when(
      is.na(MoveInDateAdjust) ~ "There's no valid move-in date",
      ymd(MoveInDateAdjust) >= mdy(ReportEnd) ~ "Move-in was after Report End Date",
      is.na(InterimID) ~ "There's no interim",
      ymd(InterimDate) != ymd(MoveInDateAdjust) ~ "Interim Date doesn't match Move In Date",
      ymd(MoveInDateAdjust) == ymd(ExitDate) ~ "Move-in = Exit Date",
      TRUE ~ "We don't know"
    )
  )

bucketed_differently <- enrollments_interims %>%
  filter(ProjectName == provider_name) %>%
  right_join(clients_that_did_not_move_in) %>%
  mutate(
    why = case_when(
      is.na(MoveInDateAdjust) ~ "ok",
      ymd(MoveInDateAdjust) >= mdy(ReportEnd) ~ "ok",
      is.na(InterimID) ~ "not ok",
      ymd(InterimDate) != ymd(MoveInDateAdjust) ~ "not ok",
      ymd(MoveInDateAdjust) == ymd(ExitDate) ~ "not ok",
      TRUE ~ "not ok"
    )
  )

summary_for_provider <- bucketed_differently %>%
  group_by(ProjectName, why) %>%
  summarise(Total = n()) %>%
  adorn_percentages(denominator = "col")
  
