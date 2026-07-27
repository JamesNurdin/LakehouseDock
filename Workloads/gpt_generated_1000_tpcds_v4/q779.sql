WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sold_time_sk,
        ss_promo_sk,
        SUM(ss_net_paid)        AS total_net_paid,
        SUM(ss_quantity)        AS total_qty,
        COUNT(*)                AS sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451000 AND 2452000          -- predicate 1
      AND ss_sales_price > 10                                 -- predicate 2
      AND ss_wholesale_cost > 5                               -- predicate 3
      AND ss_quantity >= 1                                    -- predicate 4
    GROUP BY ss_item_sk, ss_store_sk, ss_sold_time_sk, ss_promo_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    s.s_store_name,
    td.t_hour,
    p.p_promo_name,
    ss_agg.total_net_paid,
    ss_agg.total_qty,
    cs.cs_net_paid,
    cr.cr_net_loss,
    CASE WHEN ss_agg.total_net_paid > 5000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category,
    RANK()   OVER (PARTITION BY s.s_store_name ORDER BY ss_agg.total_net_paid DESC) AS store_item_rank,
    ROW_NUMBER() OVER (ORDER BY ss_agg.total_net_paid DESC)                     AS overall_rank
FROM ss_agg
JOIN store_sales ss
  ON ss.ss_item_sk   = ss_agg.ss_item_sk
 AND ss.ss_store_sk  = ss_agg.ss_store_sk
 AND ss.ss_sold_time_sk = ss_agg.ss_sold_time_sk
 AND ss.ss_promo_sk  = ss_agg.ss_promo_sk
JOIN item i
  ON i.i_item_sk = ss_agg.ss_item_sk                                          -- rule: store_sales.ss_item_sk = item.i_item_sk
JOIN store s
  ON s.s_store_sk = ss_agg.ss_store_sk                                         -- rule: store_sales.ss_store_sk = store.s_store_sk
JOIN time_dim td
  ON td.t_time_sk = ss_agg.ss_sold_time_sk                                    -- rule: store_sales.ss_sold_time_sk = time_dim.t_time_sk
JOIN promotion p
  ON p.p_promo_sk = ss_agg.ss_promo_sk                                        -- rule: store_sales.ss_promo_sk = promotion.p_promo_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = ss_agg.ss_item_sk
 AND cs.cs_sold_time_sk = ss_agg.ss_sold_time_sk                           -- rule: catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
JOIN warehouse w
  ON w.w_warehouse_sk = cs.cs_warehouse_sk                                    -- rule: catalog_sales.cs_warehouse_sk = warehouse.w_warehouse_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
 AND cr.cr_item_sk = cs.cs_item_sk                                            -- rule: catalog_returns.cr_order_number = catalog_sales.cs_order_number
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number                               -- rule: store_returns.sr_ticket_number = store_sales.ss_ticket_number
JOIN web_returns wr
  ON wr.wr_item_sk = ss_agg.ss_item_sk                                        -- rule: web_returns.wr_item_sk = item.i_item_sk
JOIN customer_address ca_bill
  ON ca_bill.ca_address_sk = cs.cs_bill_addr_sk                              -- rule: catalog_sales.cs_bill_addr_sk = customer_address.ca_address_sk
JOIN customer_address ca_ship
  ON ca_ship.ca_address_sk = cs.cs_ship_addr_sk                              -- rule: catalog_sales.cs_ship_addr_sk = customer_address.ca_address_sk
JOIN customer_address ca_refund
  ON ca_refund.ca_address_sk = cr.cr_refunded_addr_sk                       -- rule: catalog_returns.cr_refunded_addr_sk = customer_address.ca_address_sk
JOIN customer_address ca_return
  ON ca_return.ca_address_sk = cr.cr_returning_addr_sk                       -- rule: catalog_returns.cr_returning_addr_sk = customer_address.ca_address_sk
WHERE
    td.t_hour BETWEEN 8 AND 20                     -- predicate 5
  AND s.s_state = 'CA'                               -- predicate 6
  AND p.p_channel_email = 'Y'                        -- predicate 7
  AND w.w_city = 'Los Angeles'                       -- predicate 8
  AND i.i_brand = 'Brand#12'                         -- predicate 9
  AND cr.cr_net_loss > 0                            -- predicate 10
ORDER BY ss_agg.total_net_paid DESC
LIMIT 100
