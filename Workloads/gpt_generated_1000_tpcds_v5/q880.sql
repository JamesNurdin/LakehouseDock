WITH base AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        sm.sm_type AS ship_type,
        d_ret.d_year AS year,
        cp.cp_department AS department,
        ws.web_name AS web_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS returns_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE cr.cr_ship_mode_sk IN (
            SELECT sm2.sm_ship_mode_sk
            FROM ship_mode sm2
            WHERE sm2.sm_code = 'AIR'
          )
      AND d_ret.d_year BETWEEN 2000 AND 2002
    GROUP BY r.r_reason_desc, sm.sm_type, d_ret.d_year, cp.cp_department, ws.web_name
)
SELECT
    reason_desc,
    ship_type,
    year,
    department,
    web_name,
    total_return_amount,
    returns_cnt,
    avg_return_amount,
    SUM(total_return_amount) OVER (
        PARTITION BY reason_desc
        ORDER BY year, ship_type
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_by_reason,
    RANK() OVER (
        PARTITION BY reason_desc
        ORDER BY total_return_amount DESC
    ) AS rank_by_return
FROM base
ORDER BY total_return_amount DESC
LIMIT 100
