WITH sampled_catalog_page AS (
        SELECT *
        FROM catalog_page TABLESAMPLE BERNOULLI (10)
    ),
    base AS (
        SELECT
            cp.cp_catalog_page_id,
            cs.cs_order_number,
            cs.cs_net_profit,
            c.c_customer_id,
            ca.ca_state,
            hd.hd_income_band_sk,
            w.w_warehouse_name,
            cr.cr_return_amount,
            r.r_reason_desc,
            wr.wr_return_amt,
            wp.wp_url,
            w.w_warehouse_sk,
            cs.cs_warehouse_sk,
            cs.cs_item_sk
        FROM sampled_catalog_page cp
        JOIN catalog_sales cs
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer c
            ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd
            ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
           AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        FULL OUTER JOIN web_returns wr
            ON wr.wr_order_number = cs.cs_order_number
        LEFT JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN inventory inv
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
           AND inv.inv_item_sk = cs.cs_item_sk
        WHERE cp.cp_department = 'Books'
          AND c.c_preferred_cust_flag = 'Y'
          AND ca.ca_country = 'United States'
          AND hd.hd_buy_potential = 'HIGH'
          AND w.w_state = 'CA'
          AND (r.r_reason_desc LIKE '%price%' OR r.r_reason_desc IS NULL)
    ),
    ranked AS (
        SELECT
            cp_catalog_page_id,
            cs_order_number,
            cs_net_profit,
            c_customer_id,
            ca_state,
            hd_income_band_sk,
            w_warehouse_name,
            cr_return_amount,
            r_reason_desc,
            wr_return_amt,
            wp_url,
            ROW_NUMBER() OVER (PARTITION BY c_customer_id ORDER BY cs_net_profit DESC) AS profit_rank,
            SUM(cs_net_profit) OVER (
                PARTITION BY w_warehouse_name
                ORDER BY cs_order_number
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS cum_profit_by_warehouse,
            (
                SELECT MAX(cs2.cs_net_profit)
                FROM catalog_sales cs2
                WHERE cs2.cs_warehouse_sk = w_warehouse_sk
            ) AS max_warehouse_profit
        FROM base
    )
SELECT
    cp_catalog_page_id,
    cs_order_number,
    cs_net_profit,
    c_customer_id,
    ca_state,
    hd_income_band_sk,
    w_warehouse_name,
    cr_return_amount,
    r_reason_desc,
    wr_return_amt,
    wp_url,
    profit_rank,
    cum_profit_by_warehouse,
    max_warehouse_profit
FROM ranked
WHERE profit_rank <= 10
ORDER BY cs_net_profit DESC
LIMIT 100
