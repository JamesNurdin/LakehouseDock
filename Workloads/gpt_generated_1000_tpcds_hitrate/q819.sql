WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_net_paid > 100
)
SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    cc.cc_state,
    COUNT(DISTINCT sb.cs_order_number)               AS num_orders,
    SUM(sb.cs_net_paid)                              AS total_net_paid,
    AVG(sb.cs_net_profit)                            AS avg_profit,
    SUM(CASE WHEN p.p_discount_active = 'Y' THEN sb.cs_net_paid ELSE 0 END) AS discounted_net_paid,
    MIN(sb.cs_net_paid)                              AS min_net_paid,
    MAX(sb.cs_net_paid)                              AS max_net_paid
FROM sales_base sb
JOIN date_dim d               ON sb.cs_sold_date_sk   = d.d_date_sk
JOIN item i                    ON sb.cs_item_sk        = i.i_item_sk
JOIN call_center cc            ON sb.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w               ON sb.cs_warehouse_sk   = w.w_warehouse_sk
JOIN catalog_page cp           ON sb.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p               ON sb.cs_promo_sk       = p.p_promo_sk
JOIN store s                   ON s.s_closed_date_sk   = d.d_date_sk
JOIN customer c                ON sb.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN catalog_returns cr  ON cr.cr_order_number   = sb.cs_order_number
LEFT JOIN web_returns wr      ON wr.wr_item_sk        = i.i_item_sk
                               AND wr.wr_returned_date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND cc.cc_state = 'CA'
  AND s.s_state = 'CA'
  AND i.i_category = 'Women'
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = sb.cs_bill_customer_sk
          AND cr2.cr_returned_date_sk = d.d_date_sk
      )
GROUP BY CUBE (d.d_year, i.i_category, s.s_state, cc.cc_state)
HAVING COUNT(DISTINCT sb.cs_order_number) > 10
ORDER BY d.d_year DESC, i.i_category, s.s_state
