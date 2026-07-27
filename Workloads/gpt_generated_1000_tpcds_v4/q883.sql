WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ticket_number AS ticket_number,
        cr.cr_return_amount,
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_current_price,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        w.web_state,
        p.p_channel_catalog
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
        AND (cr.cr_refunded_hdemo_sk = hd.hd_demo_sk OR cr.cr_returning_hdemo_sk = hd.hd_demo_sk)
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    LEFT JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50
      AND hd.hd_income_band_sk = 5
      AND inv.inv_quantity_on_hand > 500
      AND p.p_channel_catalog = 'N'
      AND ss.ss_quantity > 2
      AND w.web_state = 'CA'
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        i_brand,
        hd_buy_potential,
        SUM(ss_net_paid) AS total_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        AVG(cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT ticket_number) AS order_count
    FROM base
    GROUP BY d_year, d_month_seq, i_brand, hd_buy_potential
    HAVING SUM(ss_net_paid) > 10000
)
SELECT
    d_year,
    d_month_seq,
    i_brand,
    hd_buy_potential,
    total_sales,
    total_return_amount,
    avg_return_amount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
