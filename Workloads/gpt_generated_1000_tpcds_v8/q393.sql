WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_sk        AS store_sk,
            d.d_date              AS sales_date,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit)      AS total_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY ss.ss_store_sk, d.d_date
    ),
    store_returns_agg AS (
        SELECT
            sr.sr_store_sk        AS store_sk,
            d.d_date              AS return_date,
            SUM(sr.sr_return_amt)    AS total_return_amt,
            SUM(sr.sr_net_loss)      AS total_return_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY sr.sr_store_sk, d.d_date
    ),
    catalog_orders AS (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_amount > 0
        EXCEPT
        SELECT sr.sr_ticket_number
        FROM store_returns sr
    )
SELECT
    s.s_store_name,
    d.d_year,
    COALESCE(ssa.total_sales, 0)          AS total_sales,
    COALESCE(sra.total_return_amt, 0)    AS total_return_amount,
    COALESCE(sra.total_return_loss, 0)   AS total_return_loss,
    (
        SELECT COUNT(DISTINCT p.p_promo_id)
        FROM promotion p
        JOIN date_dim pd ON p.p_start_date_sk = pd.d_date_sk
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND pd.d_year = d.d_year
    )                                    AS promo_count_this_year,
    CASE
        WHEN cr.cr_order_number IS NOT NULL
         AND NOT EXISTS (
                SELECT 1 FROM catalog_orders co WHERE co.cr_order_number = cr.cr_order_number
            )
        THEN 'Missing in Store Returns'
    END                                 AS missing_order_note
FROM store s
FULL OUTER JOIN store_sales_agg ssa ON s.s_store_sk = ssa.store_sk
LEFT JOIN store_returns_agg sra ON s.s_store_sk = sra.store_sk
                                 AND COALESCE(ssa.sales_date, sra.return_date) = COALESCE(ssa.sales_date, sra.return_date)
LEFT JOIN date_dim d ON d.d_date = COALESCE(ssa.sales_date, sra.return_date)
LEFT JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
                            AND ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t ON t.t_time_sk = ss.ss_sold_time_sk
LEFT JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN time_dim cr_t ON cr_t.t_time_sk = cr.cr_returned_time_sk
LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
LEFT JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = cr.cr_order_number
LEFT JOIN time_dim wr_t ON wr_t.t_time_sk = wr.wr_returned_time_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year BETWEEN 2000 AND 2002
    AND s.s_state = 'CA'
    AND w.w_city = 'Los Angeles'
    AND sm.sm_carrier = 'FedEx'
    AND r.r_reason_id = 'AAAAAAAABAAAAAA'
    AND cd.cd_gender = 'M'
ORDER BY
    total_sales DESC,
    s.s_store_name ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
