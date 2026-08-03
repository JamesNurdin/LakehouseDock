WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        cp.cp_department,
        r_sr.r_reason_desc AS store_return_reason,
        r_wr.r_reason_desc AS web_return_reason,
        cs.cs_net_paid_inc_tax,
        sr.sr_return_amt_inc_tax,
        wr.wr_return_amt_inc_tax,
        cs.cs_order_number,
        i.i_current_price,
        cs.cs_sold_date_sk,
        hd_bill.hd_income_band_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE cp.cp_department = 'Sports'
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND r_sr.r_reason_desc = 'Customer Not Satisfied'
      AND wp.wp_url LIKE 'http://www.foo.com%'
      AND cs.cs_net_paid_inc_tax > 1000
      AND sr.sr_return_amt_inc_tax < 5000
      AND hd_bill.hd_income_band_sk = 14
      AND cs.cs_sold_date_sk BETWEEN 2451910 AND 2451915
),
agg AS (
    SELECT
        s_store_name,
        s_state,
        cp_department,
        store_return_reason,
        web_return_reason,
        SUM(cs_net_paid_inc_tax) AS total_sales,
        SUM(sr_return_amt_inc_tax) AS total_store_returns,
        SUM(wr_return_amt_inc_tax) AS total_web_returns,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(i_current_price) AS avg_item_price,
        MIN(cs_sold_date_sk) AS first_sale_date_sk,
        MAX(cs_sold_date_sk) AS last_sale_date_sk
    FROM base
    GROUP BY
        s_store_name,
        s_state,
        cp_department,
        store_return_reason,
        web_return_reason
)
SELECT
    *,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num
FROM agg
ORDER BY total_sales DESC
LIMIT 100
