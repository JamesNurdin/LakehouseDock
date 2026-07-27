WITH agg AS (
    SELECT
        d.d_year AS year,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r_sr
      ON sr.sr_reason_sk = r_sr.r_reason_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND t.t_hour BETWEEN 8 AND 18
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
      AND (
            r_sr.r_reason_desc LIKE '%size%'
         OR r_wr.r_reason_desc LIKE '%size%'
          )
    GROUP BY d.d_year, COALESCE(p.p_promo_name, 'No Promo')
), final AS (
    SELECT
        year,
        promo_name,
        total_sales_amount,
        total_net_profit,
        total_store_return_loss,
        total_web_return_loss,
        sales_cnt,
        total_net_profit / NULLIF(sales_cnt, 0) AS avg_profit_per_sale,
        CASE WHEN total_net_profit > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM agg
    WHERE total_sales_amount > 50000
)
SELECT
    year,
    promo_name,
    total_sales_amount,
    total_net_profit,
    total_store_return_loss,
    total_web_return_loss,
    sales_cnt,
    avg_profit_per_sale,
    profit_category
FROM final
WHERE avg_profit_per_sale > 200
ORDER BY year DESC, total_net_profit DESC
LIMIT 100
