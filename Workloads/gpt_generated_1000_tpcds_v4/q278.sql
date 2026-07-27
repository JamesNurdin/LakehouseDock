WITH sales_agg AS (
    SELECT
        p.p_promo_id,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_type,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(sr.sr_net_loss) AS total_return_loss,
        AVG(ss.ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = ss.ss_item_sk
       AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451000 AND 2452000
      AND ss.ss_ext_sales_price > 1000
      AND ib.ib_upper_bound <= 80000
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
            AND cp.cp_department = 'Electronics'
      )
      AND EXISTS (
          SELECT 1
          FROM web_page wp
          WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
            AND wp.wp_type = 'product'
      )
    GROUP BY p.p_promo_id,
             hd.hd_income_band_sk,
             ib.ib_lower_bound,
             ib.ib_upper_bound,
             CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END
)
SELECT
    promo_type,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_return_loss) AS sum_return_loss,
    COUNT(*) AS promo_groups
FROM sales_agg
WHERE total_sales > 5000
GROUP BY promo_type
ORDER BY avg_total_sales DESC
