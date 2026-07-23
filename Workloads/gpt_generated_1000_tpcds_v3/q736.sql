WITH returns_detail AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cr.cr_item_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk
    FROM catalog_returns cr
),
agg_returns AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        sm.sm_type AS ship_mode_type,
        cc.cc_name AS call_center_name,
        SUM(rd.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(rd.cr_return_quantity) AS avg_return_quantity
    FROM returns_detail rd
    JOIN date_dim d
      ON rd.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON rd.cr_item_sk = i.i_item_sk
    JOIN call_center cc
      ON rd.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON rd.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON rd.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer refunded_cust
      ON rd.cr_refunded_customer_sk = refunded_cust.c_customer_sk
    JOIN customer returning_cust
      ON rd.cr_returning_customer_sk = returning_cust.c_customer_sk
    JOIN customer_demographics refunded_cdemo
      ON rd.cr_refunded_cdemo_sk = refunded_cdemo.cd_demo_sk
    JOIN customer_demographics returning_cdemo
      ON rd.cr_returning_cdemo_sk = returning_cdemo.cd_demo_sk
    JOIN household_demographics refunded_hdemo
      ON rd.cr_refunded_hdemo_sk = refunded_hdemo.hd_demo_sk
    JOIN household_demographics returning_hdemo
      ON rd.cr_returning_hdemo_sk = returning_hdemo.hd_demo_sk
    JOIN customer_address refunded_addr
      ON rd.cr_refunded_addr_sk = refunded_addr.ca_address_sk
    JOIN customer_address returning_addr
      ON rd.cr_returning_addr_sk = returning_addr.ca_address_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
      AND inv.inv_date_sk = d.d_date_sk
    JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
      AND p.p_start_date_sk = d.d_date_sk
    JOIN web_page wp
      ON wp.wp_creation_date_sk = d.d_date_sk
      AND wp.wp_customer_sk = returning_cust.c_customer_sk
    JOIN web_site ws
      ON ws.web_open_date_sk = d.d_date_sk
    JOIN income_band ib
      ON ib.ib_income_band_sk = returning_hdemo.hd_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_category = 'Electronics'
      AND sm.sm_type = 'AIR'
    GROUP BY
        d.d_year,
        i.i_category,
        i.i_brand,
        sm.sm_type,
        cc.cc_name
)
SELECT
    a.d_year,
    a.i_category,
    a.i_brand,
    a.ship_mode_type,
    a.call_center_name,
    a.total_net_loss,
    a.return_count,
    a.avg_return_quantity,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS loss_rank_by_year
FROM agg_returns a
ORDER BY a.total_net_loss DESC
LIMIT 100
