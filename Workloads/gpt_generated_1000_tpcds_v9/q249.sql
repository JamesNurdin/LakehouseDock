WITH agg AS (
    SELECT
        s.s_store_id AS store_id,
        d_sales.d_year AS year,
        SUM(ss.ss_net_profit) AS sum_store_sales_profit,
        SUM(cs.cs_net_profit) AS sum_catalog_sales_profit,
        SUM(sr.sr_net_loss) AS sum_store_returns_loss,
        SUM(cr.cr_net_loss) AS sum_catalog_returns_loss,
        SUM(wr.wr_net_loss) AS sum_web_returns_loss,
        SUM(ss.ss_ext_sales_price) AS sum_store_sales_amount,
        SUM(cs.cs_ext_sales_price) AS sum_catalog_sales_amount,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_transactions
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_returns ON wr.wr_returned_date_sk = d_returns.d_date_sk
    JOIN time_dim t_returns ON wr.wr_returned_time_sk = t_returns.t_time_sk
    WHERE d_sales.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND i.i_current_price > 100
      AND p.p_channel_email = 'N'
      AND sr.sr_fee > 20
      AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
      AND s.s_state = 'CA'
    GROUP BY ROLLUP (s.s_store_id, d_sales.d_year)
)
SELECT
    store_id,
    AVG(net_profit) AS avg_yearly_net_profit,
    SUM(total_sales_amount) AS total_sales_amount_across_years
FROM (
    SELECT
        store_id,
        year,
        (sum_store_sales_profit + sum_catalog_sales_profit - sum_store_returns_loss - sum_catalog_returns_loss - sum_web_returns_loss) AS net_profit,
        (sum_store_sales_amount + sum_catalog_sales_amount) AS total_sales_amount
    FROM agg
    WHERE store_id IS NOT NULL AND year IS NOT NULL
) yearly
GROUP BY store_id
HAVING AVG(net_profit) > 0
ORDER BY avg_yearly_net_profit DESC
LIMIT 100
