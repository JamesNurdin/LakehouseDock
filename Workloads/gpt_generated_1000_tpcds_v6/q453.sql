/* goal: Analyze the financial impact of store and web returns for the year 2002, broken down by store, and combine related sales, promotion, inventory and web page activity. */
WITH sr AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        sr.sr_return_quantity
    FROM store_returns sr
),
cs AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
),
wr AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_web_page_sk,
        wr.wr_reason_sk,
        wr.wr_order_number,
        wr.wr_net_loss,
        wr.wr_return_quantity
    FROM web_returns wr
)
SELECT
    s.s_store_name,
    d_sr.d_year,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_transactions,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    SUM(p.p_cost) AS total_promotion_cost,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_transactions,
    SUM(inv.inv_quantity_on_hand) AS inventory_on_return_day,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages_involved
FROM sr
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk

-- Join catalog sales for the same day
JOIN cs ON cs.cs_sold_date_sk = d_sr.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_p ON p.p_start_date_sk = d_p.d_date_sk

-- Inventory snapshot for the return day
JOIN inventory inv ON inv.inv_date_sk = d_sr.d_date_sk

-- Web returns that occurred on the same day
JOIN wr ON wr.wr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
WHERE d_sr.d_year = 2002
GROUP BY s.s_store_name, d_sr.d_year
ORDER BY total_store_return_loss DESC
LIMIT 100
