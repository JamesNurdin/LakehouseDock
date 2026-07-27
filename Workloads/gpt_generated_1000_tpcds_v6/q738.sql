WITH sales_base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        p.p_discount_active,
        ca.ca_state,
        ca.ca_city,
        CASE
            WHEN ss.ss_ext_discount_amt > 0 THEN 'Discounted'
            ELSE 'Full Price'
        END AS price_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND ss.ss_ext_sales_price > 0
      AND ss.ss_quantity >= 1
      AND p.p_discount_active = 'Y'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND p.p_channel_event <> 'Y'
),
returns_check AS (
    SELECT DISTINCT sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_net_loss > 0
)
SELECT
    sb.d_year,
    sb.d_month_seq,
    sb.ss_ticket_number,
    sb.ss_item_sk,
    sb.ss_quantity,
    sb.ss_ext_sales_price,
    sb.price_category,
    sb.ss_net_profit,
    cc.cc_name AS call_center_name,
    inv.inv_quantity_on_hand,
    sr.sr_return_quantity,
    sr.sr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY sb.d_year ORDER BY sb.ss_net_profit DESC) AS profit_rank,
    AVG(sb.ss_net_profit) OVER (
        PARTITION BY sb.d_year
        ORDER BY sb.ss_ticket_number
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS avg_net_profit_last3
FROM sales_base sb
JOIN call_center cc
    ON cc.cc_open_date_sk = sb.ss_sold_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = sb.ss_sold_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = sb.ss_ticket_number
   AND sr.sr_item_sk = sb.ss_item_sk
WHERE EXISTS (
        SELECT 1 FROM returns_check rc WHERE rc.sr_ticket_number = sb.ss_ticket_number
    )
  AND inv.inv_quantity_on_hand > 0
  AND cc.cc_state = 'CA'
  AND sb.ss_net_profit <> 0
ORDER BY sb.d_year, profit_rank
LIMIT 100
