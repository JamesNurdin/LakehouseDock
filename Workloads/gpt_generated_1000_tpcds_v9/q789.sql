WITH filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_color,
        i.i_current_price
    FROM item i
    WHERE i.i_category = 'Electronics'
      AND i.i_color = 'Red'
)
SELECT
    c.cs_sold_date_sk,
    c.cs_item_sk,
    fi.i_item_id,
    fi.i_category,
    fi.i_color,
    t.t_hour,
    w.w_warehouse_name,
    s.s_store_name,
    p.p_promo_name,
    COUNT(DISTINCT c.cs_order_number) AS distinct_orders,
    SUM(c.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    SUM(c.cs_ext_discount_amt) AS total_catalog_discount,
    AVG(CASE WHEN c.cs_net_profit > 0 THEN c.cs_net_profit END) AS avg_positive_profit,
    SUM(c.cs_net_profit) - SUM(wr.wr_net_loss) AS net_profit_after_returns,
    CASE
        WHEN SUM(c.cs_net_profit) > 100000 THEN 'High Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM catalog_sales c
JOIN filtered_items fi
    ON c.cs_item_sk = fi.i_item_sk
JOIN time_dim t
    ON c.cs_sold_time_sk = t.t_time_sk
JOIN warehouse w
    ON c.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON c.cs_promo_sk = p.p_promo_sk
JOIN customer_demographics cd_bill
    ON c.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON c.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store_sales ss
    ON ss.ss_item_sk = fi.i_item_sk
   AND ss.ss_sold_time_sk = t.t_time_sk
   AND ss.ss_promo_sk = p.p_promo_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN inventory inv
    ON inv.inv_item_sk = fi.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_item_sk = fi.i_item_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) d
WHERE t.t_hour BETWEEN 9 AND 17
  AND w.w_county = 'Franklin Parish'
  AND p.p_discount_active = 'Y'
  AND c.cs_ext_discount_amt > 500
  AND ss.ss_quantity >= 5
  AND inv.inv_quantity_on_hand > 1000
GROUP BY
    c.cs_sold_date_sk,
    c.cs_item_sk,
    fi.i_item_id,
    fi.i_category,
    fi.i_color,
    t.t_hour,
    w.w_warehouse_name,
    s.s_store_name,
    p.p_promo_name
HAVING SUM(c.cs_ext_sales_price) > 10000
LIMIT 100
