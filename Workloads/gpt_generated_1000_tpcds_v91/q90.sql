WITH catalog AS (
    SELECT
        ca.ca_state,
        i.i_category,
        cd.cd_gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_category_id = 6
      AND i.i_size = 'large'
      AND ca.ca_suite_number LIKE 'Suite %'
      AND cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 1000
      AND cs.cs_sold_date_sk BETWEEN 2451020 AND 2451080
    GROUP BY ROLLUP (ca.ca_state, i.i_category, cd.cd_gender)
),
store_ret AS (
    SELECT
        ca.ca_state,
        i.i_category,
        cd.cd_gender,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state IN ('CA', 'TX')
      AND i.i_category_id IN (1, 2, 6)
      AND ca.ca_state = s.s_state
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt > 0
      AND sr.sr_returned_date_sk BETWEEN 2451020 AND 2451080
    GROUP BY ROLLUP (ca.ca_state, i.i_category, cd.cd_gender)
),
web_ret AS (
    SELECT
        ca.ca_state,
        i.i_category,
        cd.cd_gender,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_category_id IN (6, 10)
      AND ca.ca_state LIKE 'C%'
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
      AND wr.wr_returned_date_sk BETWEEN 2451020 AND 2451080
    GROUP BY ROLLUP (ca.ca_state, i.i_category, cd.cd_gender)
),
combined_returns AS (
    SELECT
        ca_state,
        i_category,
        cd_gender,
        total_return_amt,
        total_return_qty,
        return_cnt
    FROM store_ret
    UNION ALL
    SELECT
        ca_state,
        i_category,
        cd_gender,
        total_return_amt,
        total_return_qty,
        return_cnt
    FROM web_ret
),
final AS (
    SELECT
        COALESCE(c.ca_state, r.ca_state) AS state,
        COALESCE(c.i_category, r.i_category) AS category,
        COALESCE(c.cd_gender, r.cd_gender) AS gender,
        COALESCE(c.total_sales, 0) AS total_sales,
        COALESCE(c.total_profit, 0) AS total_profit,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        COALESCE(r.total_return_qty, 0) AS total_return_qty,
        (COALESCE(c.total_sales, 0) - COALESCE(r.total_return_amt, 0)) AS net_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(c.total_sales, 0) DESC) AS global_row_num
    FROM catalog c
    FULL OUTER JOIN combined_returns r
        ON c.ca_state = r.ca_state
       AND c.i_category = r.i_category
       AND c.cd_gender = r.cd_gender
)
SELECT
    state,
    category,
    gender,
    total_sales,
    total_profit,
    total_return_amt,
    total_return_qty,
    net_sales,
    global_row_num,
    CASE
        WHEN net_sales > (SELECT AVG(total_sales) FROM catalog) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM final
ORDER BY global_row_num
LIMIT 100
