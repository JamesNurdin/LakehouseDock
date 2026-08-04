WITH sales_agg AS (
    SELECT
        i.i_category,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS store_sales_net,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_paid) AS web_sales_net,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_returns_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_returns_loss
    FROM
        store_sales ss
        INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
        INNER JOIN customer cu ON ss.ss_customer_sk = cu.c_customer_sk
        INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND p.p_channel_tv = 'N'
        AND w.w_state = 'CA'
        AND i.i_brand = 'BrandX'
    GROUP BY
        i.i_category,
        d.d_year,
        d.d_month_seq
)
SELECT
    i_category,
    d_year,
    d_month_seq,
    store_sales_net,
    web_sales_net,
    (store_sales_net + web_sales_net) AS total_sales_net,
    LAG(store_sales_net + web_sales_net) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq) AS prev_month_total,
    (store_sales_net + web_sales_net) - COALESCE(LAG(store_sales_net + web_sales_net) OVER (PARTITION BY i_category ORDER BY d_year, d_month_seq), 0) AS month_over_month_change
FROM
    sales_agg
WHERE
    (store_sales_net + web_sales_net) > 10000
ORDER BY
    i_category,
    d_year,
    d_month_seq
LIMIT 100
