WITH sales_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        sr.sr_return_amt,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        i.i_item_id,
        ca.ca_state,
        td.t_hour,
        (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = i.i_item_sk) AS max_promo_cost
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND i.i_brand = 'BrandA'
      AND ca.ca_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
      AND NOT EXISTS (
          SELECT 1 FROM web_returns wr2
          WHERE wr2.wr_item_sk = i.i_item_sk
            AND wr2.wr_returned_time_sk = td.t_time_sk
      )
)
SELECT
    i_item_id,
    ca_state,
    COUNT(DISTINCT ss_ticket_number) AS tickets_sold,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(wr_return_amt) AS total_web_returns,
    SUM(inv_quantity_on_hand) AS total_inventory,
    MAX(max_promo_cost) AS max_promo_cost
FROM sales_data
GROUP BY ROLLUP (i_item_id, ca_state)
ORDER BY i_item_id, ca_state
LIMIT 100
