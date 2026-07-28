WITH sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
        COUNT(sr.sr_ticket_number) AS return_count,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS promo_active_cnt,
        SUM(i.i_current_price * ws.ws_quantity) AS total_sales_amount
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    LEFT JOIN tpcds.store_returns sr ON i.i_item_sk = sr.sr_item_sk
        AND c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN tpcds.time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    WHERE s.s_tax_percentage > 0.05
      AND i.i_current_price > 100
      AND ib.ib_lower_bound >= 50000
      AND cd.cd_gender = 'M'
    GROUP BY s.s_store_id, i.i_item_id
)
SELECT
    store_id,
    AVG(total_web_profit) AS avg_profit_per_item,
    SUM(total_quantity_sold) AS total_quantity,
    SUM(total_return_loss) AS total_return_loss,
    SUM(promo_active_cnt) AS total_promo_active
FROM sales_agg
GROUP BY store_id
HAVING SUM(total_web_profit) > 10000
ORDER BY avg_profit_per_item DESC
LIMIT 100
