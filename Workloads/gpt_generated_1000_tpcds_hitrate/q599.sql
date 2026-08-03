WITH item_returns AS (                                                  
    SELECT                                                        
        cr.cr_item_sk,                                            
        SUM(cr.cr_net_loss) AS total_net_loss,                    
        COUNT(*)           AS return_cnt                         
    FROM catalog_returns cr                                      
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_return_amount > 100                               
    GROUP BY cr.cr_item_sk                                        
)                                                                
SELECT                                                            
    d.d_date,                                                     
    c.c_customer_id,                                              
    i.i_item_id,                                                  
    i.i_product_name,                                             
    ss.ss_quantity,                                               
    ws.ws_quantity            AS web_quantity,                   
    ss.ss_net_profit + ws.ws_net_profit - COALESCE(ir.total_net_loss, 0) AS net_profit_adj,
    CASE                                                            
        WHEN cr.cr_net_loss > 0 THEN 'Loss'                        
        ELSE 'No Loss'                                            
    END AS loss_flag,                                             
    RANK() OVER (PARTITION BY d.d_year ORDER BY (ss.ss_net_profit + ws.ws_net_profit - COALESCE(ir.total_net_loss, 0)) DESC) AS profit_rank,
    inv_l.inv_quantity_on_hand,                                    
    wp.wp_url                                                      
FROM date_dim d                                                    
-- chain: date_dim → store_sales → item → catalog_sales → catalog_returns → reason → inventory (via LATERAL) → web_sales → web_page → customer → item_returns (LEFT) 
JOIN store_sales ss       ON ss.ss_sold_date_sk = d.d_date_sk     
JOIN item i               ON ss.ss_item_sk = i.i_item_sk         
JOIN catalog_sales cs     ON cs.cs_sold_date_sk = d.d_date_sk    
                           AND cs.cs_item_sk = i.i_item_sk          
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                               AND cr.cr_item_sk = i.i_item_sk        
LEFT JOIN reason r        ON cr.cr_reason_sk = r.r_reason_sk       
CROSS JOIN LATERAL (                                              
    SELECT inv.inv_quantity_on_hand                               
    FROM inventory inv                                            
    WHERE inv.inv_date_sk = d.d_date_sk                           
      AND inv.inv_item_sk = i.i_item_sk                           
    ORDER BY inv.inv_quantity_on_hand DESC                        
    FETCH FIRST 1 ROW ONLY                                         
) AS inv_l (inv_quantity_on_hand)                               
JOIN web_sales ws        ON ws.ws_sold_date_sk = d.d_date_sk    
                           AND ws.ws_item_sk = i.i_item_sk          
JOIN web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk 
JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN item_returns ir ON ir.cr_item_sk = i.i_item_sk            
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'   
  AND i.i_brand = 'Brand#35'                                      
  AND ss.ss_quantity > 5                                          
  AND ws.ws_ext_discount_amt > 100                                
  AND inv_l.inv_quantity_on_hand < 500                            
  AND c.c_preferred_cust_flag = 'Y'                               
  AND ss.ss_quantity > (SELECT AVG(ss2.ss_quantity) FROM store_sales ss2) 
  AND EXISTS (SELECT 1 FROM reason r2 WHERE r2.r_reason_desc = 'Damage')
ORDER BY profit_rank                                                
LIMIT 100
