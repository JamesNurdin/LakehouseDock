WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS num_transactions,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MIN(cs.cs_sold_date_sk) AS min_sold_date_sk,
        MAX(cs.cs_sold_date_sk) AS max_sold_date_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND ib.ib_upper_bound >= 100000
      AND i.i_brand = 'Brand#12'
    GROUP BY cs.cs_bill_customer_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_returning_customer_sk AS customer_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(*) AS num_returns
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'remote'
    GROUP BY wr.wr_returning_customer_sk
),
combined AS (
    SELECT
        s.customer_sk,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        s.num_transactions,
        COALESCE(r.num_returns, 0) AS num_returns,
        (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM sales_agg s
    LEFT JOIN web_returns_agg r ON s.customer_sk = r.customer_sk
    WHERE s.total_sales > 5000
),
union_comb AS (
    SELECT customer_sk, net_sales, num_transactions, num_returns FROM combined WHERE net_sales >= 0
    UNION ALL
    SELECT customer_sk, net_sales, num_transactions, num_returns FROM combined WHERE net_sales < 0
)
SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    uc.net_sales,
    uc.num_transactions,
    uc.num_returns
FROM union_comb uc
JOIN customer c ON uc.customer_sk = c.c_customer_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_sales cs
    WHERE cs.cs_bill_customer_sk = uc.customer_sk
      AND cs.cs_ext_sales_price > 1000
)
  AND uc.net_sales > (
    SELECT AVG(net_sales) FROM combined
)
ORDER BY uc.net_sales DESC
LIMIT 100
