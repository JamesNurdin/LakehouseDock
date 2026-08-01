WITH base_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        cd.cd_marital_status,
        hd.hd_dep_count,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_customer_sk
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(br.sr_return_amt) AS total_return_amount,
    SUM(br.sr_return_quantity) AS total_return_quantity
FROM base_returns br
JOIN store s ON br.sr_store_sk = s.s_store_sk
WHERE s.s_geography_class = 'Unknown'
  AND s.s_division_id = 1
  AND br.cd_marital_status = 'M'
  AND br.hd_dep_count >= 3
  AND s.s_rec_start_date <= DATE '2022-12-31'
GROUP BY s.s_store_id, s.s_store_name

UNION ALL

SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(br.sr_return_amt) AS total_return_amount,
    SUM(br.sr_return_quantity) AS total_return_quantity
FROM base_returns br
JOIN store s ON br.sr_store_sk = s.s_store_sk
WHERE s.s_geography_class = 'Unknown'
  AND s.s_division_id = 1
  AND br.cd_marital_status = 'S'
  AND br.hd_dep_count <= 2
  AND s.s_rec_start_date > DATE '2021-12-31'
GROUP BY s.s_store_id, s.s_store_name

ORDER BY total_return_amount DESC
LIMIT 100
