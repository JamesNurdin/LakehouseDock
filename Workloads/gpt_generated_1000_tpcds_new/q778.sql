WITH
    sampled_store_sales AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    common_customers AS (
        SELECT ss_customer.c_customer_sk AS cust_sk
        FROM sampled_store_sales ss
        JOIN customer ss_customer ON ss.ss_customer_sk = ss_customer.c_customer_sk
        INTERSECT
        SELECT cs_bill_customer_sk
        FROM catalog_sales
    ),
    joined_data AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            d.d_date,
            t.t_hour,
            i.i_item_id,
            i.i_product_name,
            s.s_store_name,
            s.s_state,
            c.c_first_name,
            c.c_last_name,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            p.p_promo_name,
            cs.cs_ship_date_sk,
            cs.cs_ext_sales_price,
            wr.wr_return_amt,
            CASE
                WHEN ib.ib_upper_bound > 100000 THEN 'high_income'
                WHEN ib.ib_upper_bound > 50000  THEN 'mid_income'
                ELSE 'low_income'
            END AS income_category,
            ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY ss.ss_net_profit DESC) AS item_profit_rank,
            (
                SELECT SUM(wr2.wr_return_amt)
                FROM web_returns wr2
                WHERE wr2.wr_item_sk = ss.ss_item_sk
            ) AS total_item_return_amt
        FROM sampled_store_sales ss
        JOIN common_customers ccust ON ss.ss_customer_sk = ccust.cust_sk
        JOIN date_dim d                     ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t                     ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN item i                         ON ss.ss_item_sk = i.i_item_sk
        JOIN store s                        ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c                     ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd      ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN promotion p                    ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_sales cs         ON ss.ss_item_sk = cs.cs_item_sk
                                           AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
        LEFT JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN web_site ws               ON ws.web_open_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr            ON ss.ss_item_sk = wr.wr_item_sk
                                           AND ss.ss_sold_date_sk = wr.wr_returned_date_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'TX'
          AND ib.ib_upper_bound >= 50000
    )
SELECT
    jd.ss_ticket_number,
    jd.d_date,
    jd.t_hour,
    jd.i_item_id,
    jd.i_product_name,
    jd.s_store_name,
    jd.c_first_name,
    jd.c_last_name,
    jd.income_category,
    jd.item_profit_rank,
    jd.total_item_return_amt,
    jd.cs_ext_sales_price,
    jd.wr_return_amt
FROM joined_data jd
WHERE jd.item_profit_rank <= 10
ORDER BY jd.d_date DESC, jd.item_profit_rank
LIMIT 100
