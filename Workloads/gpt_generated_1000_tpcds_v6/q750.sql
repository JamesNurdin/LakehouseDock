WITH base_agg AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       d.d_day_name,
       SUM(cr.cr_net_loss) AS cat_net_loss,
       SUM(sr.sr_net_loss) AS store_net_loss,
       SUM(wr.wr_net_loss) AS web_net_loss,
       SUM(cr.cr_return_amount) AS cat_return_amount
   FROM tpcds.date_dim d
   LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN tpcds.store_returns sr   ON sr.sr_returned_date_sk   = d.d_date_sk
   LEFT JOIN tpcds.web_returns wr    ON wr.wr_returned_date_sk   = d.d_date_sk
   WHERE d.d_holiday = 'Y'
     AND regexp_like(d.d_day_name, '^S')
     AND d.d_day_name LIKE 'S%'
   GROUP BY d.d_year, d.d_month_seq, d.d_day_name
),

daily_agg AS (
   SELECT
       b.d_year,
       b.d_month_seq,
       b.d_day_name,
       CONCAT(CAST(b.d_year AS varchar), '-', LPAD(CAST(b.d_month_seq AS varchar), 2, '0')) AS year_month,
       b.cat_net_loss,
       b.store_net_loss,
       b.web_net_loss,
       b.cat_return_amount
   FROM base_agg b
)

SELECT
    da.year_month,
    da.d_day_name,
    regexp_extract(da.d_day_name, '^(.).', 1) AS first_letter,
    substring(da.d_day_name, 1, 3) AS day_abbrev,
    da.cat_net_loss,
    da.store_net_loss,
    da.web_net_loss,
    (da.cat_net_loss + da.store_net_loss + da.web_net_loss) AS total_net_loss,
    CASE
        WHEN (da.cat_net_loss + da.store_net_loss + da.web_net_loss) > (
            SELECT AVG(t.total_net_loss)
            FROM (
                SELECT
                    SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss
                FROM tpcds.date_dim d2
                LEFT JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d2.d_date_sk
                LEFT JOIN tpcds.store_returns sr   ON sr.sr_returned_date_sk   = d2.d_date_sk
                LEFT JOIN tpcds.web_returns wr    ON wr.wr_returned_date_sk   = d2.d_date_sk
                WHERE d2.d_holiday = 'Y'
                GROUP BY d2.d_year, d2.d_month_seq
            ) t
        ) THEN 'High' ELSE 'Low'
    END AS loss_category
FROM daily_agg da
WHERE EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr2
    JOIN tpcds.date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = da.d_year
      AND d2.d_month_seq = da.d_month_seq
      AND d2.d_day_name = da.d_day_name
      AND sr2.sr_reversed_charge > 100
)
ORDER BY total_net_loss DESC
LIMIT 100
