WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_date_id,
        regexp_extract(d.d_date_id, '(\\d{4})', 1) AS date_id_year,
        regexp_like(d.d_day_name, '.*e.*') AS day_name_has_e,
        substring(d.d_quarter_name, 1, 1) AS quarter_initial,
        concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1995 AND 1998
      AND cd.cd_gender = 'M'
      AND d.d_day_name LIKE 'S%'
)
SELECT
    fr.d_year,
    fr.gender_marital,
    sum(fr.cr_net_loss) AS total_net_loss,
    avg(fr.cr_return_amount) AS avg_return_amount,
    count(*) AS return_cnt,
    max(fr.date_id_year) AS max_date_id_year
FROM filtered_returns fr
WHERE fr.day_name_has_e
  AND fr.quarter_initial = 'Q'
GROUP BY fr.d_year, fr.gender_marital
ORDER BY total_net_loss DESC
LIMIT 100
