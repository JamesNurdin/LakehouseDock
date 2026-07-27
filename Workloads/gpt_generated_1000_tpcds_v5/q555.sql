WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions,
        MAX(inv.inv_quantity_on_hand) AS inventory_on_hand,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d.d_date_sk = inv.inv_date_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year = 2001
      AND d.d_moy IN (9, 12)
      AND ib.ib_upper_bound >= 100000
      AND i.i_manufact_id = 214
      AND cd.cd_gender = 'M'
      AND p.p_discount_active = 'Y'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_item_id,
        i.i_product_name,
        p.p_promo_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_item_id,
    s.i_product_name,
    s.p_promo_name,
    s.total_sales,
    s.total_returns,
    s.total_sales - s.total_returns AS net_sales,
    s.distinct_transactions,
    s.inventory_on_hand,
    s.ib_lower_bound,
    s.ib_upper_bound,
    RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_agg s
ORDER BY s.d_year, s.d_month_seq, sales_rank
LIMIT 100
