WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        d.d_year,
        d.d_date,
        cp.cp_department,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        w.w_warehouse_name,
        s.s_store_name,
        wsit.web_name,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'High'
            WHEN cs.cs_net_profit > 0  THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM
        catalog_sales cs
        JOIN date_dim d                ON cs.cs_sold_date_sk   = d.d_date_sk
        JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w               ON cs.cs_warehouse_sk    = w.w_warehouse_sk
        JOIN store s                   ON s.s_closed_date_sk   = d.d_date_sk
        JOIN web_site wsit             ON wsit.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001                              -- predicate 1 (date)
        AND cp.cp_department = 'Electronics'        -- predicate 2 (catalog_page)
        AND cs.cs_quantity > 5                      -- predicate 3 (sales quantity)
        AND w.w_warehouse_sq_ft < 2000000           -- predicate 4 (warehouse size) 
        AND s.s_floor_space > 8000000               -- predicate 5 (store floor space)
        AND wsit.web_mkt_id IN (1,2,3)               -- predicate 6 (web market)
), max_income AS (
    SELECT MAX(ib_upper_bound) AS max_ub FROM income_band
)
SELECT
    sa.cs_order_number,
    d2.d_date,
    sa.cp_department,
    sa.cs_net_profit,
    sa.profit_category,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    ws.ws_quantity,
    ROW_NUMBER() OVER (PARTITION BY d2.d_year ORDER BY sa.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM web_returns wr
            WHERE wr.wr_order_number = ws.ws_order_number
              AND wr.wr_return_quantity > 0
        ) THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_flag,
    (SELECT max_ub FROM max_income) AS max_income_upper_bound
FROM
    sales_agg sa
    JOIN catalog_returns cr   ON cr.cr_order_number = sa.cs_order_number
    JOIN reason r             ON cr.cr_reason_sk   = r.r_reason_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = sa.cs_bill_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = sa.cs_bill_hdemo_sk
    JOIN income_band ib       ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN date_dim d2          ON d2.d_date_sk = sa.cs_sold_date_sk
    JOIN web_page wp          ON wp.wp_creation_date_sk = d2.d_date_sk
    JOIN web_sales ws         ON ws.ws_sold_date_sk = d2.d_date_sk
    LEFT JOIN web_returns wr  ON wr.wr_order_number = ws.ws_order_number
WHERE
    ib.ib_upper_bound >= 50000               -- additional filter 7
    AND hd.hd_buy_potential = 'High'          -- additional filter 8
    AND r.r_reason_desc LIKE '%damage%'
ORDER BY
    profit_rank ASC,
    sa.cs_net_profit DESC
