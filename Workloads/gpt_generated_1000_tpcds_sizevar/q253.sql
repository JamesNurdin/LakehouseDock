WITH intersect_keys AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_vehicle_count > 1
    INTERSECT
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_dep_count = 0
),
except_keys AS (
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_income_band_sk = 3
    EXCEPT
    SELECT hd_demo_sk
    FROM household_demographics
    WHERE hd_buy_potential = '1000-2000'
),
sr_agg AS (
    SELECT
        sr_hdemo_sk AS hd_demo_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_store_credit > 5
      AND sr_reversed_charge < 10
      AND sr_return_quantity >= 1
      AND sr_return_amt_inc_tax > 0
    GROUP BY sr_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    sr.total_net_loss,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    wp.wp_type,
    wp.wp_image_count
FROM sr_agg sr
JOIN household_demographics hd ON sr.hd_demo_sk = hd.hd_demo_sk
JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE hd.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_keys)
  AND hd.hd_demo_sk NOT IN (SELECT hd_demo_sk FROM except_keys)
  AND wp.wp_type = 'Content'
  AND wp.wp_image_count >= 5
GROUP BY
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    sr.total_net_loss,
    wp.wp_type,
    wp.wp_image_count
ORDER BY total_sales DESC
LIMIT 100
