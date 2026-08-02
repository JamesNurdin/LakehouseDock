WITH
    promo_channels AS (
        SELECT
            p.p_promo_sk,
            TRIM(channel) AS channel
        FROM promotion p
        CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t(channel)
        WHERE p.p_channel_details IS NOT NULL
    ),
    sales_data AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_ship_cdemo_sk,
            cs.cs_ship_hdemo_sk,
            cs.cs_ship_mode_sk,
            cs.cs_warehouse_sk,
            cs.cs_item_sk,
            cs.cs_promo_sk,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_ext_discount_amt,
            cs.cs_net_profit,
            d_sold.d_year AS sold_year,
            d_sold.d_date,
            d_ship.d_year AS ship_year,
            cd_bill.cd_gender AS bill_gender,
            cd_ship.cd_gender AS ship_gender,
            hd_bill.hd_buy_potential AS bill_buy_potential,
            hd_ship.hd_buy_potential AS ship_buy_potential,
            ib_bill.ib_lower_bound AS bill_income_lower,
            ib_ship.ib_lower_bound AS ship_income_lower,
            sm.sm_type AS ship_mode_type,
            w.w_warehouse_id,
            w.w_warehouse_name,
            w.w_city,
            w.w_state,
            p.p_promo_name,
            p.p_discount_active,
            d_start.d_year AS promo_start_year,
            d_end.d_year AS promo_end_year,
            inv.inv_quantity_on_hand,
            web.wp_url,
            web.wp_type,
            d_access.d_year AS web_access_year
        FROM catalog_sales cs
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship
            ON cs.cs_ship_date_sk = d_ship.d_date_sk
        LEFT JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        LEFT JOIN customer_demographics cd_ship
            ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        LEFT JOIN household_demographics hd_bill
            ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        LEFT JOIN household_demographics hd_ship
            ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        LEFT JOIN income_band ib_bill
            ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
        LEFT JOIN income_band ib_ship
            ON hd_ship.hd_income_band_sk = ib_ship.ib_income_band_sk
        LEFT JOIN ship_mode sm
            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN date_dim d_start
            ON p.p_start_date_sk = d_start.d_date_sk
        LEFT JOIN date_dim d_end
            ON p.p_end_date_sk = d_end.d_date_sk
        LEFT JOIN inventory inv
            ON inv.inv_date_sk = d_sold.d_date_sk
           AND inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN web_page web
            ON web.wp_creation_date_sk = d_sold.d_date_sk
        LEFT JOIN date_dim d_access
            ON web.wp_access_date_sk = d_access.d_date_sk
        WHERE d_sold.d_year = 2001
          AND p.p_discount_active = 'Y'
          AND hd_bill.hd_buy_potential = '501-1000'
          AND cs.cs_quantity > 0
          AND cs.cs_net_paid > 0
    ),
    returns_data AS (
        SELECT
            sr.sr_returned_date_sk,
            sr.sr_item_sk,
            sr.sr_customer_sk,
            sr.sr_cdemo_sk,
            sr.sr_hdemo_sk,
            sr.sr_reason_sk,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_net_loss,
            d_ret.d_year,
            cd_ret.cd_gender AS ret_gender,
            hd_ret.hd_buy_potential AS ret_buy_potential,
            ib_ret.ib_lower_bound AS ret_income_lower,
            r.r_reason_desc,
            inv_ret.inv_quantity_on_hand,
            w_ret.w_warehouse_id,
            w_ret.w_warehouse_name,
            w_ret.w_city,
            w_ret.w_state
        FROM store_returns sr
        JOIN date_dim d_ret
            ON sr.sr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN customer_demographics cd_ret
            ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
        LEFT JOIN household_demographics hd_ret
            ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
        LEFT JOIN income_band ib_ret
            ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
        LEFT JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        LEFT JOIN inventory inv_ret
            ON inv_ret.inv_date_sk = d_ret.d_date_sk
        LEFT JOIN warehouse w_ret
            ON inv_ret.inv_warehouse_sk = w_ret.w_warehouse_sk
        WHERE d_ret.d_year = 2001
          AND sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 0
    ),
    agg_sales AS (
        SELECT
            w.w_warehouse_id,
            w.w_warehouse_name,
            d_sold.d_year,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_ext_discount_amt) AS total_discount,
            AVG(cs.cs_quantity) AS avg_quantity,
            COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
            SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
        FROM catalog_sales cs
        JOIN date_dim d_sold
            ON cs.cs_sold_date_sk = d_sold.d_date_sk
        LEFT JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN inventory inv
            ON inv.inv_date_sk = d_sold.d_date_sk
           AND inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE d_sold.d_year = 2001
          AND cs.cs_net_paid > 0
          AND cs.cs_quantity > 0
        GROUP BY w.w_warehouse_id, w.w_warehouse_name, d_sold.d_year
    ),
    agg_returns AS (
        SELECT
            w_ret.w_warehouse_id,
            w_ret.w_warehouse_name,
            d_ret.d_year,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN date_dim d_ret
            ON sr.sr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN inventory inv_ret
            ON inv_ret.inv_date_sk = d_ret.d_date_sk
        LEFT JOIN warehouse w_ret
            ON inv_ret.inv_warehouse_sk = w_ret.w_warehouse_sk
        WHERE d_ret.d_year = 2001
          AND sr.sr_return_amt > 0
        GROUP BY w_ret.w_warehouse_id, w_ret.w_warehouse_name, d_ret.d_year
    ),
    combined AS (
        SELECT
            s.w_warehouse_id,
            s.w_warehouse_name,
            s.d_year,
            s.total_net_paid,
            s.total_discount,
            s.avg_quantity,
            s.order_cnt,
            s.total_inventory_on_hand,
            r.total_return_amt,
            r.total_net_loss,
            (s.total_net_paid - COALESCE(r.total_return_amt, 0)) AS net_sales_minus_returns,
            ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY (s.total_net_paid - COALESCE(r.total_return_amt, 0)) DESC) AS sales_rank
        FROM agg_sales s
        LEFT JOIN agg_returns r
            ON s.w_warehouse_id = r.w_warehouse_id
           AND s.d_year = r.d_year
    ),
    promo_sales_tv AS (
        SELECT
            p.p_promo_sk,
            pc.channel,
            SUM(cs.cs_net_paid) AS net_paid_tv
        FROM catalog_sales cs
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN promo_channels pc
            ON p.p_promo_sk = pc.p_promo_sk
        WHERE pc.channel = 'TV'
          AND cs.cs_net_paid > 0
        GROUP BY p.p_promo_sk, pc.channel
    ),
    promo_sales_radio AS (
        SELECT
            p.p_promo_sk,
            pc.channel,
            SUM(cs.cs_net_paid) AS net_paid_radio
        FROM catalog_sales cs
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN promo_channels pc
            ON p.p_promo_sk = pc.p_promo_sk
        WHERE pc.channel = 'Radio'
          AND cs.cs_net_paid > 0
        GROUP BY p.p_promo_sk, pc.channel
    ),
    promo_union AS (
        SELECT p.p_promo_sk, pc.channel, net_paid_tv AS net_paid
        FROM promo_sales_tv p
        JOIN promo_channels pc
            ON p.p_promo_sk = pc.p_promo_sk
        UNION ALL
        SELECT p.p_promo_sk, pc.channel, net_paid_radio AS net_paid
        FROM promo_sales_radio p
        JOIN promo_channels pc
            ON p.p_promo_sk = pc.p_promo_sk
    ),
    promo_tv_only AS (
        SELECT p.p_promo_sk
        FROM promo_sales_tv p
        EXCEPT
        SELECT p.p_promo_sk
        FROM promo_sales_radio p
    ),
    promo_filtered AS (
        SELECT pu.p_promo_sk, pu.channel, pu.net_paid
        FROM promo_union pu
        WHERE pu.p_promo_sk IN (SELECT p_promo_sk FROM promo_tv_only)
    ),
    final_result AS (
        SELECT
            c.w_warehouse_id,
            c.w_warehouse_name,
            c.d_year,
            c.net_sales_minus_returns,
            c.sales_rank,
            pf.channel,
            pf.net_paid
        FROM combined c
        LEFT JOIN promo_filtered pf
            ON 1 = 1
        WHERE c.sales_rank <= 10
    )
SELECT
    f.w_warehouse_id,
    f.w_warehouse_name,
    f.d_year,
    f.net_sales_minus_returns,
    f.sales_rank,
    f.channel,
    f.net_paid
FROM final_result f
ORDER BY f.d_year, f.net_sales_minus_returns DESC, f.sales_rank
