/*
Goal: Compute the average total return amount per return reason for the year 2001, after applying several demographic, geographic and product filters, and keep only reasons whose average loss exceeds $1,000. The query joins all twelve selected tables, uses a CTE for the first level aggregation, applies a HAVING filter on the outer aggregation, and includes a semi‑join via EXISTS.
*/
WITH returns_agg AS (
    SELECT
        d_date.d_year,
        r.r_reason_desc,
        SUM(sr.sr_return_amt)            AS store_return_amt,
        SUM(wr.wr_return_amt)            AS web_return_amt,
        SUM(sr.sr_return_quantity)       AS store_qty,
        SUM(wr.wr_return_quantity)       AS web_qty
    FROM store_returns sr
    JOIN date_dim d_date
        ON sr.sr_returned_date_sk = d_date.d_date_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d_date.d_date_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN inventory i
        ON i.inv_date_sk = d_date.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_date.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_date.d_date_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d_date.d_year = 2001
        AND hd.hd_vehicle_count >= 2
        AND ib.ib_lower_bound >= 50000
        AND r.r_reason_desc = 'Damaged'
        AND ws.web_country = 'United States'
        AND ca.ca_state = 'CA'
        AND cd.cd_education_status = 'College'
        AND cp.cp_type = 'Catalog'
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_department = 'Books'
              AND cp2.cp_start_date_sk = d_date.d_date_sk
        )
    GROUP BY d_date.d_year, r.r_reason_desc
)
SELECT
    reason_desc,
    AVG(total_return_amt) AS avg_total_return_amt,
    SUM(total_qty)          AS sum_total_qty
FROM (
    SELECT
        d_year,
        r_reason_desc       AS reason_desc,
        (store_return_amt + web_return_amt) AS total_return_amt,
        (store_qty + web_qty)               AS total_qty
    FROM returns_agg
) agg
GROUP BY reason_desc
HAVING AVG(total_return_amt) > 1000
ORDER BY avg_total_return_amt DESC
LIMIT 100
