WITH filtered_items AS (
    SELECT i_item_sk, i_brand, i_current_price, i_category
    FROM item
    WHERE i_current_price BETWEEN 20 AND 100
      AND i_brand IN ('BrandA', 'BrandB', 'BrandC')
      AND i_category = 'Electronics'
),
joined_data AS (
    SELECT
        ca.ca_state,
        fi.i_brand,
        cd.cd_gender,
        hd.hd_vehicle_count,
        sr.sr_net_loss,
        fi.i_current_price
    FROM store_returns sr
    JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
    LEFT JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = fi.i_item_sk
    RIGHT OUTER JOIN promotion p ON p.p_item_sk = fi.i_item_sk
    WHERE ca.ca_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_vehicle_count >= 2
      AND inv.inv_warehouse_sk = 19
      AND p.p_discount_active = 'Y'
      AND p.p_response_target > 0
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_item_sk = fi.i_item_sk
            AND p2.p_channel_radio = 'N'
      )
),
agg AS (
    SELECT
        ca_state,
        i_brand,
        cd_gender,
        hd_vehicle_count,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(i_current_price) AS avg_price
    FROM joined_data
    GROUP BY ca_state, i_brand, cd_gender, hd_vehicle_count
    HAVING SUM(sr_net_loss) > 0
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_net_loss DESC) AS rnk
    FROM agg
)
SELECT
    ca_state,
    i_brand,
    cd_gender,
    hd_vehicle_count,
    total_net_loss,
    return_cnt,
    avg_price
FROM ranked
WHERE rnk <= 3
ORDER BY total_net_loss DESC
LIMIT 100
