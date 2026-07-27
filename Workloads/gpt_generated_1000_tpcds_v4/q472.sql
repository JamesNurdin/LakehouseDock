WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number,
        i.i_item_sk,
        i.i_brand,
        i.i_color,
        p.p_promo_sk,
        p.p_purpose,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        c.c_customer_sk,
        cd.cd_demo_sk,
        hd.hd_demo_sk,
        ib.ib_upper_bound,
        inv.inv_quantity_on_hand,
        cs.cs_order_number,
        cp.cp_department,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND i.i_item_sk = cr.cr_item_sk
    JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450800 AND 2450900
      AND inv.inv_quantity_on_hand > 500
      AND ib.ib_upper_bound <= 50000
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1 FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_demo = 'N'
      )
)
SELECT
    s_store_name,
    s_state,
    cp_department,
    ib_upper_bound,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    MAX(inv_quantity_on_hand) AS max_inventory_on_hand
FROM base
GROUP BY
    s_store_name,
    s_state,
    cp_department,
    ib_upper_bound
ORDER BY total_net_paid DESC
LIMIT 100
