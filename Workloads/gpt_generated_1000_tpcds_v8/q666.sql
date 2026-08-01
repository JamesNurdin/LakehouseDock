WITH
    sales_data AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            d_sales.d_year,
            i.i_item_sk,
            i.i_category,
            i.i_brand,
            i.i_current_price,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_net_profit,
            ss.ss_promo_sk,
            p.p_promo_name,
            CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag,
            c.c_customer_sk,
            c.c_first_name,
            c.c_last_name,
            ca.ca_city,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            inv.inv_quantity_on_hand,
            w.w_warehouse_name,
            ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_paid DESC) AS category_rank
        FROM store_sales ss
        JOIN date_dim d_sales
            ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN call_center cc
            ON cc.cc_open_date_sk = d_sales.d_date_sk
        LEFT JOIN (
                SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
            ) inv
            ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d_sales.d_date_sk
        LEFT JOIN warehouse w
            ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE d_sales.d_year = 2002
    ),
    returns_data AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_returned_date_sk,
            dr.d_year AS return_year,
            i.i_item_sk,
            i.i_category,
            i.i_brand,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_net_loss,
            c.c_customer_sk,
            ca.ca_city,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            inv_ret.inv_quantity_on_hand,
            w2.w_warehouse_name,
            ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY sr.sr_return_amt DESC) AS return_rank
        FROM store_returns sr
        JOIN date_dim dr
            ON sr.sr_returned_date_sk = dr.d_date_sk
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c
            ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca
            ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN promotion p
            ON p.p_item_sk = i.i_item_sk
        LEFT JOIN (
                SELECT * FROM inventory TABLESAMPLE BERNOULLI (5)
            ) inv_ret
            ON inv_ret.inv_item_sk = i.i_item_sk
           AND inv_ret.inv_date_sk = dr.d_date_sk
        LEFT JOIN warehouse w2
            ON inv_ret.inv_warehouse_sk = w2.w_warehouse_sk
        WHERE dr.d_year = 2002
    )
SELECT
    combined.ticket_number,
    combined.d_year,
    combined.i_category,
    combined.i_brand,
    combined.quantity,
    combined.net_amount,
    combined.promo_active_flag,
    combined.rank,
    combined.max_item_sales
FROM (
    SELECT
        sd.ss_ticket_number AS ticket_number,
        sd.d_year,
        sd.i_category,
        sd.i_brand,
        sd.ss_quantity AS quantity,
        sd.ss_net_paid AS net_amount,
        sd.promo_active_flag,
        sd.category_rank AS rank,
        (SELECT MAX(ss2.ss_net_paid)
         FROM store_sales ss2
         WHERE ss2.ss_item_sk = sd.i_item_sk) AS max_item_sales
    FROM sales_data sd
    WHERE sd.category_rank = 1

    UNION

    SELECT
        rd.sr_ticket_number AS ticket_number,
        rd.return_year AS d_year,
        rd.i_category,
        rd.i_brand,
        rd.sr_return_quantity AS quantity,
        rd.sr_return_amt AS net_amount,
        0 AS promo_active_flag,
        rd.return_rank AS rank,
        (SELECT MAX(sr2.sr_return_amt)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = rd.i_item_sk) AS max_item_sales
    FROM returns_data rd
    WHERE rd.return_rank = 1
) AS combined
ORDER BY combined.net_amount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
