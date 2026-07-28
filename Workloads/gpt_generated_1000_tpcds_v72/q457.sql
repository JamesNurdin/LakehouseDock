WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_quantity) AS avg_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY
        ss.ss_sold_date_sk,
        d.d_year,
        i.i_category,
        i.i_brand,
        s.s_store_name,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_item_sk
)
SELECT
    b.d_year,
    b.i_category,
    b.i_brand,
    b.s_store_name,
    b.total_net_paid,
    b.sales_cnt,
    b.avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY b.d_year ORDER BY b.total_net_paid DESC) AS yearly_rank
FROM base b
WHERE b.d_year BETWEEN 1998 AND 2000
  AND b.i_category = 'Electronics'
  AND b.hd_buy_potential = '>10000'
  AND b.ib_lower_bound >= 50000
  AND b.s_store_name LIKE '%Store%'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        WHERE cs.cs_item_sk = b.ss_item_sk
          AND cs.cs_sold_date_sk = b.ss_sold_date_sk
          AND cc.cc_name = 'Call Center 1'
          AND sm.sm_type = 'AIR'
      )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws
        WHERE ws.ws_item_sk = b.ss_item_sk
          AND ws.ws_sold_date_sk = b.ss_sold_date_sk
      )
ORDER BY b.total_net_paid DESC
LIMIT 100
