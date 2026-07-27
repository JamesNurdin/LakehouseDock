WITH catalog_sales_data AS (
    SELECT
        cp.cp_department,
        p.p_promo_name,
        t.t_hour,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cp.cp_catalog_number = 10
      AND t.t_hour BETWEEN 9 AND 17
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = 'HIGH'
    GROUP BY cp.cp_department, p.p_promo_name, t.t_hour, cd.cd_gender, hd.hd_buy_potential
),
web_sales_data AS (
    SELECT
        ws.ws_web_page_sk,
        p.p_promo_name,
        t.t_hour,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_email = 'Y'
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.ws_quantity > 1
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = 'MEDIUM'
    GROUP BY ws.ws_web_page_sk, p.p_promo_name, t.t_hour, cd.cd_gender, hd.hd_buy_potential
),
returns_data AS (
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    WHERE EXISTS (
        SELECT 1
        FROM household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_upper_bound > 150000
          AND hd.hd_demo_sk = ws.ws_ship_hdemo_sk
    )
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    combined.source,
    combined.identifier,
    combined.p_promo_name,
    combined.t_hour,
    combined.total_sales,
    combined.avg_profit,
    combined.distinct_orders,
    rd.total_return_amount,
    rd.return_cnt
FROM (
    SELECT
        'catalog' AS source,
        cp_department AS identifier,
        p_promo_name,
        t_hour,
        total_sales,
        avg_profit,
        distinct_orders
    FROM catalog_sales_data
    UNION
    SELECT
        'web' AS source,
        CAST(ws_web_page_sk AS VARCHAR) AS identifier,
        p_promo_name,
        t_hour,
        total_sales,
        avg_profit,
        distinct_orders
    FROM web_sales_data
) AS combined
JOIN returns_data rd
  ON combined.t_hour = (rd.wr_returned_date_sk % 24)
WHERE combined.source = 'catalog'
ORDER BY combined.total_sales DESC
LIMIT 100
