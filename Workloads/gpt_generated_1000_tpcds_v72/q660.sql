WITH unified_sales AS (
    SELECT
        p.p_promo_id,
        td.t_hour,
        hd.hd_income_band_sk,
        ss.ss_net_profit AS store_profit,
        cs.cs_net_profit AS catalog_profit,
        ws.ws_net_profit AS web_profit,
        -sr.sr_net_loss AS store_return_loss,
        -wr.wr_net_loss AS web_return_loss,
        CASE 
            WHEN ss.ss_quantity > 5 THEN 'HighQtyStore'
            WHEN cs.cs_quantity > 5 THEN 'HighQtyCatalog'
            WHEN ws.ws_quantity > 5 THEN 'HighQtyWeb'
            ELSE 'LowQty'
        END AS qty_category
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        td.t_hour BETWEEN 8 AND 20
        AND hd.hd_income_band_sk IN (1, 2, 3)
        AND p.p_discount_active = 'Y'
        AND ss.ss_quantity > 0
        AND cs.cs_quantity > 0
        AND ws.ws_quantity > 0
        AND ss.ss_net_profit IS NOT NULL
)
SELECT
    p_promo_id,
    t_hour,
    SUM(store_profit + catalog_profit + web_profit + store_return_loss + web_return_loss) AS total_net_amount,
    COUNT(*) AS transaction_cnt,
    AVG(CASE 
            WHEN qty_category = 'HighQtyStore' THEN store_profit
            WHEN qty_category = 'HighQtyCatalog' THEN catalog_profit
            WHEN qty_category = 'HighQtyWeb' THEN web_profit
            ELSE 0
        END) AS avg_high_qty_profit
FROM unified_sales
GROUP BY p_promo_id, t_hour
HAVING SUM(store_profit + catalog_profit + web_profit) > 1000
ORDER BY total_net_amount DESC
LIMIT 100
