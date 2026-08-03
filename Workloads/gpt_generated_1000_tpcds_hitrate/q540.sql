WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        d.d_year,
        d.d_quarter_name,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND i.i_brand = 'Brand#12'
      AND ss.ss_quantity > 5
      AND ss.ss_item_sk IN (
          SELECT DISTINCT i_item_sk
          FROM item
          WHERE i_category = 'Sports'
      )
)
SELECT
    ROW_NUMBER() OVER (PARTITION BY sb.d_year ORDER BY sb.ss_net_profit DESC) AS row_num,
    sb.d_year,
    sb.d_quarter_name,
    sb.i_brand,
    sb.i_category,
    sb.p_promo_name,
    sb.ss_quantity,
    sb.ss_net_profit,
    COALESCE(sr.sr_return_quantity, 0) AS return_quantity,
    COALESCE(sr.sr_net_loss, 0)        AS net_loss,
    ws.ws_quantity,
    ws.ws_net_profit,
    CASE WHEN ws.ws_quantity > 10 THEN 'High' ELSE 'Low' END AS quantity_bucket
FROM sales_base sb
FULL OUTER JOIN store_returns sr
    ON sb.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN web_sales ws
    ON ws.ws_sold_date_sk = sb.ss_sold_date_sk
   AND ws.ws_item_sk = sb.ss_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
WHERE (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
ORDER BY sb.d_year, row_num
