WITH intersect_orders AS (
    SELECT cs.cs_order_number AS order_num
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 500
    INTERSECT
    SELECT wr.wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
),
base AS (
    SELECT
        i.i_category,
        i.i_brand,
        hd.hd_buy_potential,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cr.cr_return_quantity,
        wr.wr_return_quantity AS web_return_qty,
        ss.ss_quantity,
        cc.cc_manager,
        cs.cs_net_profit,
        p.p_discount_active
    FROM store_sales ss
    RIGHT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_class_id IN (1, 4, 5)
      AND p.p_discount_active = 'Y'
      AND cc.cc_manager = 'Mark Hightower'
      AND cs.cs_net_profit > 0
      AND ss.ss_quantity >= 2
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_cost < 1000
      )
      AND cs.cs_order_number IN (SELECT order_num FROM intersect_orders)
),
agg AS (
    SELECT
        i_category,
        i_brand,
        hd_buy_potential,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_quantity) AS total_catalog_returns,
        SUM(web_return_qty) AS total_web_returns,
        COUNT(DISTINCT cs_order_number) AS orders_cnt
    FROM base
    GROUP BY GROUPING SETS (
        (i_category, i_brand, hd_buy_potential),
        (i_category, i_brand),
        (i_category),
        ()
    )
)
SELECT
    i_category,
    i_brand,
    hd_buy_potential,
    total_sales,
    total_catalog_returns,
    total_web_returns,
    orders_cnt,
    RANK() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
