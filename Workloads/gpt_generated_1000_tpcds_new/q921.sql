WITH ss AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2451346 AND 2452238
      AND ss_quantity > 1
),
sr_ret AS (
    SELECT *
    FROM store_returns
    WHERE sr_return_quantity > 0
),
wr_ret AS (
    SELECT *
    FROM web_returns
    WHERE wr_return_quantity > 0
),
intersect_items AS (
    SELECT ss_item_sk FROM ss
    INTERSECT
    SELECT ws_item_sk FROM web_sales
),
full_returns AS (
    SELECT sr_ret.sr_returned_date_sk   AS return_date_sk,
           sr_ret.sr_return_quantity    AS store_return_qty,
           wr_ret.wr_return_quantity    AS web_return_qty,
           r.r_reason_desc
    FROM sr_ret
    FULL OUTER JOIN wr_ret
          ON sr_ret.sr_ticket_number = wr_ret.wr_order_number
    LEFT JOIN reason r
          ON sr_ret.sr_reason_sk = r.r_reason_sk
)
SELECT s.s_state,
       i.i_category,
       COUNT(DISTINCT c.c_customer_sk)                         AS unique_customers,
       SUM(ss.ss_ext_sales_price)                              AS total_sales,
       SUM(ss.ss_net_profit)                                   AS total_profit,
       AVG(ss.ss_quantity)                                     AS avg_quantity,
       MIN(ss.ss_sold_date_sk)                                 AS first_sale_date_sk,
       MAX(ss.ss_sold_date_sk)                                 AS last_sale_date_sk,
       SUM(COALESCE(sr_ret.sr_return_quantity, 0) +
           COALESCE(wr_ret.wr_return_quantity, 0))            AS total_returns
FROM ss
JOIN item i                 ON ss.ss_item_sk = i.i_item_sk
JOIN customer c             ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib          ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s                ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p            ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN inventory inv     ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN warehouse w       ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN sr_ret            ON ss.ss_ticket_number = sr_ret.sr_ticket_number
LEFT JOIN reason r          ON sr_ret.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_sales ws      ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN wr_ret            ON ws.ws_order_number = wr_ret.wr_order_number
WHERE c.c_birth_year = 1965
  AND ca.ca_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND p.p_channel_event = 'N'
  AND p.p_response_target = 1
  AND ss.ss_item_sk IN (SELECT ss_item_sk FROM intersect_items)
GROUP BY s.s_state, i.i_category
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
