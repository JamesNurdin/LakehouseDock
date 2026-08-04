WITH common_items AS (
    SELECT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
    INTERSECT
    SELECT ws.ws_item_sk
    FROM web_sales ws
    WHERE ws.ws_quantity > 0
),
base AS (
    SELECT 
        i.i_item_id,
        i.i_category,
        p.p_promo_name,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        lr.max_return_amount
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN store_sales ss
        ON ss.ss_item_sk = cs.cs_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = cs.cs_item_sk
    JOIN item i
        ON i.i_item_sk = cs.cs_item_sk
    JOIN promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    JOIN reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN customer c
        ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN customer_address ca
        ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN customer_demographics cd
        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    JOIN household_demographics hd
        ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN web_site wsit
        ON wsit.web_site_sk = ws.ws_web_site_sk
    JOIN common_items ci
        ON ci.item_sk = cs.cs_item_sk
    CROSS JOIN LATERAL (
        SELECT MAX(cr2.cr_return_amount) AS max_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
    ) lr
    WHERE p.p_channel_radio = 'N'
      AND r.r_reason_desc = 'Wrong size'
      AND c.c_birth_year = 1975
      AND w.w_state = 'TX'
      AND i.i_brand = 'Brand#12'
      AND cs.cs_item_sk NOT IN (
          SELECT cs3.cs_item_sk
          FROM catalog_sales cs3
          WHERE cs3.cs_quantity = 0
      )
    GROUP BY i.i_item_id, i.i_category, p.p_promo_name, r.r_reason_desc, lr.max_return_amount
)
SELECT i_item_id,
       i_category,
       p_promo_name,
       r_reason_desc,
       total_net_loss,
       order_cnt,
       avg_sales_price,
       max_return_amount
FROM base
UNION
SELECT i_item_id,
       i_category,
       p_promo_name,
       r_reason_desc,
       total_net_loss,
       order_cnt,
       avg_sales_price,
       max_return_amount
FROM base
WHERE avg_sales_price > 20
ORDER BY total_net_loss DESC
LIMIT 100
