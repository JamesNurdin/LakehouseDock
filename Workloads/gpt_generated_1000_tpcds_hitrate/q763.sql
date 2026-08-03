WITH sales_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    RIGHT OUTER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE i.i_current_price BETWEEN 10 AND 200
      AND t.t_hour BETWEEN 8 AND 20
      AND c.c_birth_year BETWEEN 1960 AND 1990
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
    GROUP BY p.p_promo_sk, p.p_promo_name
),
returns_agg AS (
    SELECT
        p.p_promo_sk,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE cc.cc_state = 'CA'
      AND p.p_channel_tv = 'Y'
      AND i.i_brand_id = 5
      AND i.i_manager_id IN (
          SELECT DISTINCT i2.i_manager_id
          FROM item i2
          WHERE i2.i_color = 'red'
      )
      AND cr.cr_return_quantity > 0
      AND cr.cr_return_amount > 0
      AND cp.cp_department = 'Sports'
    GROUP BY p.p_promo_sk
),
promo_without_sales AS (
    SELECT p.p_promo_sk, p.p_promo_name
    FROM promotion p
    EXCEPT
    SELECT ss.ss_promo_sk, p2.p_promo_name
    FROM store_sales ss
    JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
)
SELECT
    s.p_promo_name,
    s.total_store_profit,
    r.total_catalog_return_loss,
    r.total_web_return_loss,
    (s.total_store_profit - COALESCE(r.total_catalog_return_loss, 0) - COALESCE(r.total_web_return_loss, 0)) AS net_contribution,
    CASE WHEN pnws.p_promo_sk IS NOT NULL THEN 'No Sales' ELSE 'Has Sales' END AS sales_status
FROM sales_agg s
LEFT JOIN returns_agg r ON s.p_promo_sk = r.p_promo_sk
LEFT JOIN promo_without_sales pnws ON s.p_promo_sk = pnws.p_promo_sk
WHERE s.store_txn_cnt >= 10
  AND (r.catalog_return_cnt IS NULL OR r.catalog_return_cnt < 5)
ORDER BY net_contribution DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
