WITH sales_data AS (
    SELECT
        d.d_year,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        i.i_category,
        i.i_brand,
        i.i_color,
        c.c_first_name,
        c.c_last_name,
        hd.hd_buy_potential,
        s.s_store_name,
        s.s_state,
        cp.cp_department,
        r.r_reason_desc,
        ss.ss_net_paid,
        sr.sr_net_loss,
        wr.wr_net_loss,
        CASE WHEN cs.cs_net_profit > 1000 THEN cs.cs_net_profit END AS high_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN store_sales ss ON ss.ss_item_sk = cs.cs_item_sk
        AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND c.c_first_name = 'Tammy'
      AND hd.hd_buy_potential = '>10000'
      AND s.s_state = 'CA'
      AND cp.cp_department = 'Electronics'
)
SELECT
    sd.d_year,
    sd.s_store_name,
    sd.i_category,
    sd.cp_department,
    COUNT(DISTINCT sd.cs_order_number) AS orders,
    SUM(sd.cs_quantity) AS total_quantity,
    SUM(sd.cs_sales_price * sd.cs_quantity) AS total_sales,
    SUM(sd.ss_net_paid) AS total_store_paid,
    SUM(sd.sr_net_loss) AS total_store_returns,
    SUM(sd.wr_net_loss) AS total_web_returns,
    AVG(sd.high_profit) AS avg_high_profit,
    MAX(sd.cs_sales_price) AS max_unit_price
FROM sales_data sd
GROUP BY
    sd.d_year,
    sd.s_store_name,
    sd.i_category,
    sd.cp_department
HAVING COUNT(*) > 10
ORDER BY total_sales DESC
LIMIT 100
