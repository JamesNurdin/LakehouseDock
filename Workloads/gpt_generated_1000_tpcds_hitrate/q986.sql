WITH agg AS (
    SELECT
        d.d_date,
        s.s_store_name,
        p.p_promo_name,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers,
        CASE WHEN SUM(ss.ss_net_profit) > 100000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc ON cc.cc_open_date_sk = ss.ss_sold_date_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND cd.cd_gender = 'F'
      AND hd.hd_income_band_sk = 5
    GROUP BY d.d_date, s.s_store_name, p.p_promo_name
    HAVING SUM(ss.ss_net_paid) > 50000
)
SELECT
    d_date,
    s_store_name,
    p_promo_name,
    total_store_sales,
    total_web_sales,
    total_return_amount,
    distinct_store_customers,
    distinct_web_customers,
    profit_category,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY d_date) AS rn,
    LAG(total_store_sales) OVER (PARTITION BY s_store_name ORDER BY d_date) AS prev_day_sales
FROM agg
ORDER BY total_store_sales DESC
LIMIT 100
